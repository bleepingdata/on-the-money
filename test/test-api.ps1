# Script: test-api.ps1
# Purpose: Simple integration tests for the OTM Flask API using Invoke-RestMethod.
# Usage: Ensure the API is running (python otm-api/otm-api.py) before running this script.

# Configuration
$BaseUrl = "http://127.0.0.1:5000"

function Test-Endpoint {
    param (
        [string]$Method,
        [string]$Path,
        [string]$ExpectedContent
    )

    $Uri = "$BaseUrl$Path"
    Write-Host "Testing [$Method] $Path ... " -NoNewline

    try {
        # Invoke the API endpoint
        $response = Invoke-RestMethod -Method $Method -Uri $Uri -ErrorAction Stop
        
        # Normalize response if necessary (Invoke-RestMethod handles plain text automatically)
        if ($response -eq $ExpectedContent) {
            Write-Host "PASS" -ForegroundColor Green
        }
        else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Host "    Expected: '$ExpectedContent'"
            Write-Host "    Actual:   '$response'"
        }
    }
    catch {
        # Handle connection errors (e.g., API not running) or HTTP 500 errors
        Write-Host "ERROR" -ForegroundColor Red
        Write-Host "    Details: $_"
        if ($_.Exception.Response) {
             Write-Host "    Status:  $($_.Exception.Response.StatusCode)"
        }
    }
}

# ---------------------------------------------------------
# Execute Tests
# ---------------------------------------------------------
Write-Host "Running API Tests against $BaseUrl" -ForegroundColor Cyan
Write-Host "Ensure the Flask API is running before executing this script.`n"

# Test 1: Trigger Summary Population
Test-Endpoint -Method "PUT" -Path "/summary/populate" -ExpectedContent "Population of fact.account_summary_by_month complete"