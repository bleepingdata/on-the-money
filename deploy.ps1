#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys On The Money application files and database objects.

.DESCRIPTION
    Copies Python source files to the application folder and deploys database
    objects (database, schema, tables, sequences, views, functions, default data)
    to PostgreSQL. The database is created if it does not already exist.
    The PostgreSQL password is requested once and reused for all connections.

    Every deploy targets a named environment, defined by a git-ignored JSON file under
    environments\ (sub-folders allowed) that gives the environment name and the location of
    its private folder. Connection details (and the password, if stored) are read from
    connection_strings.py in that private folder.

.PARAMETER Environment
    Mandatory. Environment name, e.g. 'sample_environment'; matches "name" in an environments\*.json file.
    Lowercase letters, digits and underscores, starting with a letter.

.PARAMETER Target
    What to deploy: 'All', 'Python', or 'Database'. Default is 'All'.

.PARAMETER AppPath
    Destination folder for Python application files. Default: C:\otm\src

.PARAMETER SkipDefaultData
    If specified, skips loading default accounts and rules data.

.PARAMETER SkipPrivateData
    If specified, skips running the private init scripts.

.EXAMPLE
    .\deploy.ps1 -Environment sample_environment
    # Deploys everything to the database named in environments\sample_environment.json

.EXAMPLE
    .\deploy.ps1 -Environment sample_environment -Target Database -SkipDefaultData -SkipPrivateData
    # Deploys only the database objects

.EXAMPLE
    .\deploy.ps1 -Environment sample_environment -Target Python -AppPath "D:\apps\otm"
    # Only copies Python files to a custom path
#>

Param(
    [Parameter(Mandatory, Position = 0)]
    [ValidatePattern('^[a-z][a-z0-9_]{0,62}$')]
    [string]$Environment,

    [ValidateSet('All', 'Python', 'Database')]
    [string]$Target = 'All',

    [string]$AppPath = 'C:\otm\src',

    [switch]$SkipDefaultData,

    [switch]$SkipPrivateData
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

. (Join-Path $RepoRoot 'otm-environment.ps1')
$envConfig = Get-OtmEnvironment -Environment $Environment -RepoRoot $RepoRoot
$DbHost = $envConfig.DbHost
$DbPort = $envConfig.DbPort
$DbName = $envConfig.DbName
$DbUser = $envConfig.DbUser
$PrivateEnvPath = $envConfig.PrivatePath

# ─── Helpers ────────────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor Cyan
}

function Write-Section {
    param([string]$Message)
    Write-Host "`n╔══ $Message ══╗" -ForegroundColor Green
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Invoke-Psql {
    param([string]$SqlFile)

    $relativePath = [System.IO.Path]::GetRelativePath($RepoRoot, $SqlFile)
    Write-Step $relativePath

    $result = & psql --host=$DbHost --port=$DbPort --username=$DbUser --dbname=$DbName -f $SqlFile 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Failure "Failed: $relativePath"
        Write-Host ($result | Out-String) -ForegroundColor Red
        throw "psql failed on $relativePath (exit code $LASTEXITCODE)"
    }
}

function Invoke-SqlFolder {
    param(
        [string]$FolderPath,
        [string]$Label
    )

    if (-not (Test-Path $FolderPath)) {
        Write-Failure "$Label folder not found: $FolderPath"
        return
    }

    $files = Get-ChildItem -Path $FolderPath -Filter '*.sql' | Sort-Object Name
    if ($files.Count -eq 0) {
        Write-Step "${Label}: no files to deploy"
        return
    }

    Write-Step "$Label ($($files.Count) files)"
    foreach ($file in $files) {
        Invoke-Psql -SqlFile $file.FullName
    }
}

# ─── Python Deployment ──────────────────────────────────────────────────────────

function Deploy-Python {
    Write-Section "Deploying Python Application"

    # Ensure target directory exists
    if (-not (Test-Path $AppPath)) {
        New-Item -Path $AppPath -ItemType Directory -Force | Out-Null
        Write-Step "Created directory: $AppPath"
    }

    # Ensure templates subdirectory exists
    $templatesTarget = Join-Path $AppPath 'templates'
    if (-not (Test-Path $templatesTarget)) {
        New-Item -Path $templatesTarget -ItemType Directory -Force | Out-Null
    }

    # Copy API files
    $apiSource = Join-Path $RepoRoot 'otm-api'
    $apiFiles = Get-ChildItem -Path $apiSource -Filter '*.py'
    foreach ($file in $apiFiles) {
        Copy-Item -Path $file.FullName -Destination $AppPath -Force
        Write-Step "otm-api/$($file.Name)"
    }

    # Copy templates
    $templateSource = Join-Path $apiSource 'templates'
    $templateFiles = Get-ChildItem -Path $templateSource -Filter '*.html'
    foreach ($file in $templateFiles) {
        Copy-Item -Path $file.FullName -Destination $templatesTarget -Force
        Write-Step "otm-api/templates/$($file.Name)"
    }

    # Copy standalone Python scripts
    $pythonSource = Join-Path $RepoRoot 'python'
    $pythonFiles = Get-ChildItem -Path $pythonSource -Filter '*.py'
    foreach ($file in $pythonFiles) {
        Copy-Item -Path $file.FullName -Destination $AppPath -Force
        Write-Step "python/$($file.Name)"
    }

    # Per-environment credentials live in the private folder, not the repo
    $connFile = Join-Path $PrivateEnvPath 'connection_strings.py'
    $connCount = 0
    if (Test-Path $connFile) {
        Copy-Item -Path $connFile -Destination $AppPath -Force
        Write-Step "connection_strings.py (from private folder)"
        $connCount = 1
    }
    else {
        Write-Warning "No connection_strings.py in $PrivateEnvPath - run .\init-environment.ps1 -Environment $Environment and set the password. The API will not start without it."
    }

    # Environment pointers let the deployed import scripts resolve -e <environment>
    $envSource = Join-Path $RepoRoot 'environments'
    $envFiles = @(Get-ChildItem -Path $envSource -Filter '*.json' -Recurse -File)
    foreach ($file in $envFiles) {
        $relative = $file.FullName.Substring($envSource.Length).TrimStart('\')
        $envTarget = Join-Path (Join-Path $AppPath 'environments') $relative
        New-Item -Path (Split-Path $envTarget) -ItemType Directory -Force | Out-Null
        Copy-Item -Path $file.FullName -Destination $envTarget -Force
        Write-Step "environments/$relative"
    }

    $totalFiles = $apiFiles.Count + $templateFiles.Count + $pythonFiles.Count + $connCount + $envFiles.Count
    Write-Success "Deployed $totalFiles files to $AppPath"
}

# ─── Database Deployment ────────────────────────────────────────────────────────

function Deploy-Database {
    Write-Section "Deploying Database Objects"

    # Verify psql is available
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        throw "psql not found on PATH. Install PostgreSQL client tools and ensure psql is in your PATH."
    }

    $setPgPassword = [string]::IsNullOrEmpty($env:PGPASSWORD)
    try {
        if ($setPgPassword -and $envConfig.DbPassword) {
            $env:PGPASSWORD = $envConfig.DbPassword
        }
        elseif ($setPgPassword) {
            $securePassword = Read-Host "Password for user $DbUser" -AsSecureString
            try {
                $env:PGPASSWORD = [System.Net.NetworkCredential]::new('', $securePassword).Password
            }
            finally {
                $securePassword.Dispose()
            }
        }

        $sqlRoot = Join-Path $RepoRoot 'sql'

        # 0. Database (created via the maintenance 'postgres' database if missing)
        Write-Step "Checking database '$DbName'..."
        $dbExists = & psql --host=$DbHost --port=$DbPort --username=$DbUser --dbname=postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DbName';" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot connect to PostgreSQL at ${DbHost}:${DbPort}. Check host, port and credentials."
        }
        if ($dbExists -ne '1') {
            Write-Step "Creating database '$DbName'"
            $createFile = Join-Path $sqlRoot 'database\create-database.sql'
            $result = & psql --host=$DbHost --port=$DbPort --username=$DbUser --dbname=postgres -v "dbname=$DbName" -f $createFile 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create database '$DbName': $($result | Out-String)"
            }
        }

        # Test connectivity to the target database
        Write-Step "Testing connection to ${DbHost}:${DbPort}/${DbName}..."
        $testResult = & psql --host=$DbHost --port=$DbPort --username=$DbUser --dbname=$DbName -c "SELECT 1;" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot connect to PostgreSQL at ${DbHost}:${DbPort}/${DbName}. Check credentials."
        }
        Write-Success "Connected successfully"

        # 1. Schema
        Write-Step "Schema"
        $schemaFile = Join-Path $sqlRoot 'schema\create-schema.sql'
        if (Test-Path $schemaFile) { Invoke-Psql -SqlFile $schemaFile }

        # 2. Tables
        Write-Step "Tables"
        Invoke-SqlFolder -FolderPath (Join-Path $sqlRoot 'tables') -Label 'Tables'

        # 3. Sequences
        Write-Step "Sequences"
        Invoke-SqlFolder -FolderPath (Join-Path $sqlRoot 'sequence') -Label 'Sequences'

        # 4. Views (order can matter for dependent views)
        Write-Step "Views"
        Invoke-SqlFolder -FolderPath (Join-Path $sqlRoot 'views') -Label 'Views'

        # 5. Functions
        Write-Step "Functions"
        Invoke-SqlFolder -FolderPath (Join-Path $sqlRoot 'functions') -Label 'Functions'

        # 6. Default data (on unless -SkipDefaultData)
        if (-not $SkipDefaultData) {
            Write-Step "Default Data"
            Invoke-SqlFolder -FolderPath (Join-Path $sqlRoot 'default-data') -Label 'Default Data'
        }

        # 7. Private init scripts for this environment, kept outside the repository
        $privateInit = Join-Path $PrivateEnvPath 'init'
        if ($SkipPrivateData) {
            Write-Step "Private Init: skipped"
        }
        elseif (Test-Path $privateInit) {
            Invoke-SqlFolder -FolderPath $privateInit -Label 'Private Init'
        }
        else {
            Write-Step "Private Init: no folder for '$Environment' (run .\init-environment.ps1 -Environment $Environment)"
        }

        Write-Success "Database deployment complete"
    }
    finally {
        if ($setPgPassword) {
            Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        }
    }
}

# ─── Main ───────────────────────────────────────────────────────────────────────

$startTime = Get-Date
Write-Host "`n━━━ On The Money Deploy ━━━" -ForegroundColor Yellow
Write-Host "  Environment: $Environment"
Write-Host "  Target:   $Target"
Write-Host "  App Path: $AppPath"
Write-Host "  Database: ${DbUser}@${DbHost}:${DbPort}/${DbName}"
Write-Host ""

try {
    if ($Target -in @('All', 'Python')) {
        Deploy-Python
    }

    if ($Target -in @('All', 'Database')) {
        Deploy-Database
    }

    $elapsed = (Get-Date) - $startTime
    Write-Host "`n━━━ Deploy completed in $($elapsed.TotalSeconds.ToString('0.0'))s ━━━`n" -ForegroundColor Green
}
catch {
    Write-Host "`n━━━ Deploy FAILED ━━━" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
