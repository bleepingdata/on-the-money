#Requires -Version 7.0
<#
.SYNOPSIS
    Creates the private (non-repository) data folder for one On The Money environment.

.DESCRIPTION
    Creates <PrivateRoot>\<Environment> OUTSIDE the git repository, holding data that must
    never be committed or shared with AI tools:
        init\      psql scripts run by deploy.ps1 after the default data (bank details, users)
        bank-exports\   bank transaction files (Excel, OFX)
        notes\     personal markdown notes

    The environment must already be defined in a git-ignored environments\*.json file, which
    names the environment and gives the private folder location (privatePath). Connection
    details live only in the generated connection_strings.py in that folder.
    Existing files are never overwritten.

.PARAMETER Environment
    Mandatory. Environment name, e.g. 'sample_environment'.

.PARAMETER Database
    Database name for a newly created connection_strings.py. Default: otm_<Environment>.

.PARAMETER DbHost
    Host for a newly created connection_strings.py. Default: localhost.

.PARAMETER DbPort
    Port for a newly created connection_strings.py. Default: 5432.

.PARAMETER DbUser
    User for a newly created connection_strings.py. Default: postgres.

.EXAMPLE
    .\init-environment.ps1 -Environment sample_environment
    # Creates the folder named by privatePath in the sample_environment config
#>

Param(
    [Parameter(Mandatory, Position = 0)]
    [ValidatePattern('^[a-z][a-z0-9_]{0,62}$')]
    [string]$Environment,

    [ValidatePattern('^[a-z][a-z0-9_]{0,62}$')]
    [string]$Database = "otm_$Environment",

    [string]$DbHost = 'localhost',
    [int]$DbPort = 5432,
    [string]$DbUser = 'postgres'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

. (Join-Path $RepoRoot 'otm-environment.ps1')
$envConfig = Get-OtmEnvironment -Environment $Environment -RepoRoot $RepoRoot -SkipConnection
$envPath = $envConfig.PrivatePath

# Refuse a location inside the repository, where git and AI tools could see it
$repoFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') + '\'
if (($envPath.TrimEnd('\') + '\').StartsWith($repoFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Private path '$envPath' is inside the repository. Change privatePath in '$($envConfig.ConfigPath)'."
}

foreach ($folder in 'init', 'bank-exports', 'notes') {
    New-Item -ItemType Directory -Path (Join-Path $envPath $folder) -Force | Out-Null
}

# Incoming folder for each bank account mapped in the environment file
foreach ($account in $envConfig.BankAccounts) {
    if ($account.incomingFolder) {
        New-Item -ItemType Directory -Path (Join-Path $envPath $account.incomingFolder) -Force | Out-Null
    }
}

function Set-FileIfMissing {
    param([string]$FilePath, [string]$Content)
    if (-not (Test-Path $FilePath)) {
        Set-Content -Path $FilePath -Value $Content -Encoding utf8
    }
}

Set-FileIfMissing $envConfig.ConnectionPath @"
# Database connection for the '$Environment' environment. Single source of truth: read by
# deploy.ps1 and copied next to otm-api.py. Set s_password, or leave CHANGE_ME to be prompted on deploy.
s_databasename = "$Database"
s_username = "$DbUser"
s_password = "CHANGE_ME"
s_host = "$DbHost"
n_port = $DbPort
"@

$database = (Read-OtmConnection -Path $envConfig.ConnectionPath).DbName

Set-FileIfMissing (Join-Path $envPath 'README.md') @"
# On The Money - private data for '$Environment'

Sensitive data for the '$Environment' environment (database '$database').
Lives outside the git repository on purpose.

- Never copy this folder into the repository or add it to a VS Code workspace.
- Do not ask AI assistants to open, read or run anything from here.

| Folder | Contents |
|--------|----------|
| ``connection_strings.py`` | Database credentials for the Flask API; copied to the app folder by ``deploy.ps1`` |
| ``init\`` | psql scripts run in file-name order by ``deploy.ps1 -Environment $Environment`` |
| ``bank-exports\<account folders>`` | Incoming folders from the ``bankAccounts`` mapping; drop OFX/Excel files here and run ``python/ImportBankFiles.py -e $Environment`` |
| ``notes\`` | Personal markdown notes |
"@

Set-FileIfMissing (Join-Path $envPath 'init\01_bank.accounts.sql') @'
-- Private bank account set-up. Edit the values, then run deploy.ps1 for this environment.
-- bank_account_type_id: 1 = cash, 2 = debt, 3 = credit (see sql/default-data/01_bank.account_type.sql)
insert into bank.account (bank_account_type_id, description, open_date, close_date)
values
    (1, 'Everyday', '2020-01-01', '2099-12-31')
on conflict (description) do nothing;
'@

Write-Host "Private folder ready for '$Environment' (database '$database'): $envPath" -ForegroundColor Green
