<#
.SYNOPSIS
    Shared helper for locating and loading On The Money environment configuration.

.DESCRIPTION
    Dot-source this file, then call Get-OtmEnvironment. Used by deploy.ps1 and init-environment.ps1.

    An environment is defined by a small, git-ignored JSON file under environments\
    (sub-folders allowed; the file name is free):

        { "name": "sample_environment", "privatePath": "~\\otm-private\\sample_environment" }

    "name" is what you pass as -Environment (defaults to the file name without extension).
    "privatePath" is the folder holding the environment's private data, outside the repository.
    "~" and %ENV_VARS% are expanded.

    All connection details live ONLY in <privatePath>\connection_strings.py, the same file the
    Flask API imports (s_databasename, s_username, s_password, s_host, n_port).
#>

function Read-OtmConnection {
    <#
    .SYNOPSIS
        Reads connection details from a connection_strings.py file.

    .OUTPUTS
        PSCustomObject with DbHost, DbPort, DbName, DbUser, DbPassword (empty if unset or placeholder).
    #>
    param([Parameter(Mandatory)][string]$Path)

    $text = Get-Content -Path $Path -Raw
    function Get-PyValue([string]$Variable) {
        $m = [regex]::Match($text, "(?m)^\s*$Variable\s*=\s*(?:[""'](?<s>.*?)[""']|(?<n>\d+))\s*(?:#.*)?$")
        if (-not $m.Success) { return $null }
        if ($m.Groups['s'].Success) { return $m.Groups['s'].Value }
        return $m.Groups['n'].Value
    }

    $db = Get-PyValue 's_databasename'
    if ([string]::IsNullOrWhiteSpace($db)) {
        throw "'$Path' must define s_databasename."
    }
    if ($db -notmatch '^[a-z][a-z0-9_]{0,62}$') {
        throw "Database name '$db' in '$Path' must be lowercase letters, digits and underscores, starting with a letter."
    }

    $password = Get-PyValue 's_password'
    if ($password -eq 'CHANGE_ME') { $password = $null }

    [pscustomobject]@{
        DbHost     = if (Get-PyValue 's_host') { Get-PyValue 's_host' } else { 'localhost' }
        DbPort     = if (Get-PyValue 'n_port') { Get-PyValue 'n_port' } else { '5432' }
        DbName     = $db
        DbUser     = if (Get-PyValue 's_username') { Get-PyValue 's_username' } else { 'postgres' }
        DbPassword = $password
    }
}

function Get-OtmEnvironment {
    <#
    .SYNOPSIS
        Loads the configuration for a named environment.

    .PARAMETER Environment
        Environment name (the "name" in the JSON, or the file name if "name" is absent).

    .PARAMETER RepoRoot
        Repository root containing the environments folder.

    .PARAMETER SkipConnection
        Do not require or read connection_strings.py (used when scaffolding a new private folder).

    .OUTPUTS
        PSCustomObject with Name, ConfigPath, PrivatePath, ConnectionPath and, unless
        -SkipConnection, DbHost, DbPort, DbName, DbUser, DbPassword.
    #>
    param(
        [Parameter(Mandatory)][string]$Environment,
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$SkipConnection
    )

    $envRoot = Join-Path $RepoRoot 'environments'
    $configs = @()
    if (Test-Path $envRoot) {
        foreach ($file in Get-ChildItem -Path $envRoot -Filter '*.json' -Recurse -File) {
            try {
                $json = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            }
            catch {
                throw "Invalid JSON in '$($file.FullName)': $($_.Exception.Message)"
            }
            $name = if ($json.name) { [string]$json.name } else { $file.BaseName }
            $configs += [pscustomobject]@{ Name = $name; Path = $file.FullName; Json = $json }
        }
    }

    $found = @($configs | Where-Object { $_.Name -eq $Environment })
    if ($found.Count -eq 0) {
        $names = if ($configs.Count) { ($configs.Name | Sort-Object) -join ', ' } else { '(none)' }
        throw "No configuration found for environment '$Environment' under '$envRoot'. Available: $names. See environments\README.md to create one."
    }
    if ($found.Count -gt 1) {
        throw "Environment '$Environment' is ambiguous; defined in: $($found.Path -join '; ')"
    }

    $configPath = $found[0].Path
    $rawPrivate = [string]$found[0].Json.privatePath
    if ([string]::IsNullOrWhiteSpace($rawPrivate)) {
        throw "Environment file '$configPath' must define 'privatePath'."
    }
    $expanded = [System.Environment]::ExpandEnvironmentVariables($rawPrivate)
    if ($expanded -eq '~' -or $expanded.StartsWith('~\') -or $expanded.StartsWith('~/')) {
        $expanded = Join-Path $HOME $expanded.Substring(1).TrimStart('\', '/')
    }
    $privatePath = [System.IO.Path]::GetFullPath($expanded)
    $connectionPath = Join-Path $privatePath 'connection_strings.py'

    $result = [ordered]@{
        Name           = $Environment
        ConfigPath     = $configPath
        PrivatePath    = $privatePath
        ConnectionPath = $connectionPath
        BankAccounts   = @($found[0].Json.bankAccounts)
    }

    if (-not $SkipConnection) {
        if (-not (Test-Path $connectionPath)) {
            throw "Missing '$connectionPath'. Run .\init-environment.ps1 -Environment $Environment to create it."
        }
        $conn = Read-OtmConnection -Path $connectionPath
        foreach ($p in $conn.PSObject.Properties) { $result[$p.Name] = $p.Value }
    }

    [pscustomobject]$result
}
