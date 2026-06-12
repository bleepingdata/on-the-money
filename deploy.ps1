#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys On The Money application files and database objects.

.DESCRIPTION
    Copies Python source files to the application folder and deploys database
    objects (schema, tables, sequences, views, functions) to PostgreSQL.

.PARAMETER Target
    What to deploy: 'All', 'Python', or 'Database'. Default is 'All'.

.PARAMETER AppPath
    Destination folder for Python application files. Default: C:\otm\src

.PARAMETER DbHost
    PostgreSQL host. Default: localhost

.PARAMETER DbPort
    PostgreSQL port. Default: 6432

.PARAMETER DbName
    PostgreSQL database name. Default: otm

.PARAMETER DbUser
    PostgreSQL username. Default: postgres

.PARAMETER IncludeDefaultData
    If specified, also deploys default accounts and rules data.

.EXAMPLE
    .\deploy.ps1
    # Deploys everything with default settings

.EXAMPLE
    .\deploy.ps1 -Target Database -DbPort 5432
    # Only deploys database objects to port 5432

.EXAMPLE
    .\deploy.ps1 -Target Python -AppPath "D:\apps\otm"
    # Only copies Python files to a custom path
#>

Param(
    [ValidateSet('All', 'Python', 'Database')]
    [string]$Target = 'All',

    [string]$AppPath = 'C:\otm\src',

    [string]$DbHost = 'localhost',
    [string]$DbPort = '6432',
    [string]$DbName = 'otm',
    [string]$DbUser = 'postgres',

    [switch]$IncludeDefaultData
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

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
        Write-Step "$Label: no files to deploy"
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

    $totalFiles = $apiFiles.Count + $templateFiles.Count + $pythonFiles.Count
    Write-Success "Deployed $totalFiles files to $AppPath"
}

# ─── Database Deployment ────────────────────────────────────────────────────────

function Deploy-Database {
    Write-Section "Deploying Database Objects"

    # Verify psql is available
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        throw "psql not found on PATH. Install PostgreSQL client tools and ensure psql is in your PATH."
    }

    # Test connectivity
    Write-Step "Testing connection to ${DbHost}:${DbPort}/${DbName}..."
    $testResult = & psql --host=$DbHost --port=$DbPort --username=$DbUser --dbname=$DbName -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot connect to PostgreSQL at ${DbHost}:${DbPort}/${DbName}. Ensure the database exists and credentials are correct."
    }
    Write-Success "Connected successfully"

    $sqlRoot = Join-Path $RepoRoot 'sql'

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

    # 6. Default data (optional)
    if ($IncludeDefaultData) {
        Write-Step "Default Data"
        Invoke-SqlFolder -FolderPath (Join-Path $sqlRoot 'default-data') -Label 'Default Data'
    }

    Write-Success "Database deployment complete"
}

# ─── Main ───────────────────────────────────────────────────────────────────────

$startTime = Get-Date
Write-Host "`n━━━ On The Money Deploy ━━━" -ForegroundColor Yellow
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
