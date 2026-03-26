# Script: test-api.ps1
# Purpose: Simple integration tests for the OTM Flask API using Invoke-RestMethod.
# Usage: Ensure the API is running (python otm-api/otm-api.py) before running this script.

# Configuration
$BaseUrl = "http://127.0.0.1:5000"

function Test-Endpoint {
    param (
        [string]$Method,
        [string]$Path,
        [string]$Body = $null,
        [string]$ExpectedContent
    )

    $Uri = "$BaseUrl$Path"
    Write-Host "Testing [$Method] $Path ... " -NoNewline

    try {
        # Invoke the API endpoint
        $params = @{
            Method      = $Method
            Uri         = $Uri
            ErrorAction = "Stop"
        }
        if ($Body) {
            $params["Body"] = $Body
            $params["ContentType"] = "application/json"
        }

        $response = Invoke-RestMethod @params
        
        # If response is JSON object with message property, compare that
        $actual = if ($response.message) { $response.message } else { $response }

        if ($actual -eq $ExpectedContent) {
            Write-Host "PASS" -ForegroundColor Green
        }
        else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Host "    Expected: '$ExpectedContent'"
            Write-Host "    Actual:   '$actual'"
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

# Test 2: Add Expense Rule
$RulePayload = @{
    s_expense_account = "TestGroceries"
    s_cash_account    = "TestChecking"
    n_priority        = 10
} | ConvertTo-Json

Test-Endpoint -Method "POST" -Path "/rules/expense" -Body $RulePayload -ExpectedContent "Rule added successfully"

# Test 3: Add Expense Rule with All Optional Parameters
$FullRulePayload = @{
    s_expense_account                 = "TestGroceriesFull"
    s_cash_account                    = "TestChecking"
    n_priority                        = 5
    s_bank_account                    = "Everyday"
    b_is_deposit                      = $false
    s_type                            = "POS"
    s_other_party_bank_account_number = "00-0000-0000000-00"
    s_details                         = "Countdown"
    s_particulars                     = "Weekly Shop"
    s_code                            = "1234"
    s_reference                       = "Ref"
    s_ofx_name                        = "COUNTDOWN"
    s_ofx_memo                        = "memo"
    s_wildcard_field                  = "COUNTDOWN*"
} | ConvertTo-Json

Test-Endpoint -Method "POST" -Path "/rules/expense" -Body $FullRulePayload -ExpectedContent "Rule added successfully"

# Test 5: Get Bank Accounts
# Note: This endpoint returns a dynamic list, so we verify the call succeeds and returns a response.
$Uri = "$BaseUrl/accounts/bank"
Write-Host "Testing [GET] /accounts/bank ... " -NoNewline

try {
    $response = Invoke-RestMethod -Method Get -Uri $Uri -ErrorAction Stop
    Write-Host "PASS (Response received)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host "    Details: $_"
}

# Test 6: Get Books Accounts
$Uri = "$BaseUrl/accounts/books"
Write-Host "Testing [GET] /accounts/books ... " -NoNewline

try {
    $response = Invoke-RestMethod -Method Get -Uri $Uri -ErrorAction Stop
    Write-Host "PASS (Response received)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host "    Details: $_"
}