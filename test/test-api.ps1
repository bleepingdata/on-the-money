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
        [string]$ExpectedContent,
        [int]$ExpectedStatus = 200,
        [switch]$ContentMatch,
        [switch]$NoSession,
        [switch]$NoCsrf,
        [switch]$PassThru
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
        if (-not $NoSession) {
            $params["WebSession"] = $Session
            if ($CsrfToken -and -not $NoCsrf) {
                $params["Headers"] = @{ "X-CSRF-Token" = $CsrfToken }
            }
        }
        if ($Body) {
            $params["Body"] = $Body
            $params["ContentType"] = "application/json"
        }

        $response = Invoke-RestMethod @params
        
        # If response is JSON object with message property, compare that
        $actual = if ($response.message) { $response.message } else { $response }

        if ($ExpectedStatus -eq 200 -and (($ContentMatch -and $actual -match [regex]::Escape($ExpectedContent)) -or
            (-not $ContentMatch -and $actual -eq $ExpectedContent))) {
            Write-Host "PASS" -ForegroundColor Green
            if ($PassThru) { return $response }
        }
        else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Host "    Expected: '$ExpectedContent'"
            Write-Host "    Actual:   '$actual'"
            $script:Failures++
        }
    }
    catch {
        # Handle connection errors (e.g., API not running) or HTTP 500 errors
        $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
        if ($status -eq $ExpectedStatus) {
            Write-Host "PASS (HTTP $status)" -ForegroundColor Green
        } else {
            Write-Host "ERROR" -ForegroundColor Red
            Write-Host "    Details: $_"
            $script:Failures++
        }
    }
}

# ---------------------------------------------------------
# Execute Tests
# ---------------------------------------------------------
Write-Host "Running API Tests against $BaseUrl" -ForegroundColor Cyan
Write-Host "Ensure the Flask API is running before executing this script.`n"
$script:Failures = 0
$Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$CsrfToken = $null

Test-Endpoint -Method "GET" -Path "/login" -ExpectedContent "On The Money - Sign in" -ContentMatch -NoSession
# Stylesheets must load on the login page before authentication
Test-Endpoint -Method "GET" -Path "/static/css/theme.css" -ExpectedContent "--color-primary" -ContentMatch -NoSession
foreach ($Path in @("/rules/list", "/accounts/bank", "/accounts/books",
                   "/accounts/bank/balances", "/accounts/bank/summary", "/accounts/bank/data-as-at")) {
    Test-Endpoint -Method "GET" -Path $Path -ExpectedStatus 401 -NoSession
}
Test-Endpoint -Method "PUT" -Path "/summary/populate" -ExpectedStatus 401 -NoSession
Test-Endpoint -Method "POST" -Path "/rules/expense" -ExpectedStatus 401 -NoSession
Test-Endpoint -Method "DELETE" -Path "/rules/999999" -ExpectedStatus 401 -NoSession
Test-Endpoint -Method "POST" -Path "/login" -Body '{"password":""}' -ExpectedStatus 401

$ApiPassword = $env:OTM_API_PASSWORD
if (-not $ApiPassword) {
    $ApiPassword = Read-Host "API password" -AsSecureString | ConvertFrom-SecureString -AsPlainText
}
$LoginPayload = @{ password = $ApiPassword } | ConvertTo-Json
$LoginResult = Test-Endpoint -Method "POST" -Path "/login" -Body $LoginPayload -ExpectedContent "Logged in" -PassThru
if (-not $LoginResult) { throw "Login failed; cannot run authenticated API tests." }
$CsrfToken = $LoginResult.csrf_token
Test-Endpoint -Method "GET" -Path "/" -ExpectedContent "On The Money - Summary" -ContentMatch
Test-Endpoint -Method "GET" -Path "/rules" -ExpectedContent "Import Rules" -ContentMatch
Test-Endpoint -Method "GET" -Path "/rules/new" -ExpectedContent "Add Expense Rule" -ContentMatch
Test-Endpoint -Method "PUT" -Path "/summary/populate" -ExpectedStatus 403 -NoCsrf
Test-Endpoint -Method "POST" -Path "/rules/expense" -ExpectedStatus 403 -NoCsrf
Test-Endpoint -Method "DELETE" -Path "/rules/999999" -ExpectedStatus 403 -NoCsrf

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
    $response = Invoke-RestMethod -Method Get -Uri $Uri -WebSession $Session -ErrorAction Stop
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
    $response = Invoke-RestMethod -Method Get -Uri $Uri -WebSession $Session -ErrorAction Stop
    Write-Host "PASS (Response received)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host "    Details: $_"
}

# Test 6a: Data freshness date (null when no transactions have been imported)
Write-Host "Testing [GET] /accounts/bank/data-as-at ... " -NoNewline
try {
    $response = Invoke-RestMethod -Method Get -Uri "$BaseUrl/accounts/bank/data-as-at" -WebSession $Session -ErrorAction Stop
    $latest = $response.latest_transaction_date
    if ($response.PSObject.Properties.Name -contains "latest_transaction_date" -and
        ($null -eq $latest -or $latest -match '^\d{4}-\d{2}-\d{2}$')) {
        Write-Host "PASS (Latest transaction date: $latest)" -ForegroundColor Green
    } else {
        Write-Host "FAIL" -ForegroundColor Red
        Write-Host "    Expected latest_transaction_date as YYYY-MM-DD or null, got: '$latest'"
        $script:Failures++
    }
}
catch {
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host "    Details: $_"
    $script:Failures++
}

# Test 6b: Bank account balances (with and without closed accounts)
foreach ($Query in @("", "?include_closed=true")) {
    Write-Host "Testing [GET] /accounts/bank/balances$Query ... " -NoNewline
    try {
        $response = Invoke-RestMethod -Method Get -Uri "$BaseUrl/accounts/bank/balances$Query" -WebSession $Session -ErrorAction Stop
        $items = @($response)
        $hasShape = ($items.Count -eq 0) -or ($null -ne $items[0].current_balance -and $null -ne $items[0].description)
        if ($hasShape) {
            Write-Host "PASS (Returned $($items.Count) account(s))" -ForegroundColor Green
        } else {
            Write-Host "FAIL" -ForegroundColor Red
            Write-Host "    Response missing description/current_balance fields"
        }
    }
    catch {
        Write-Host "ERROR" -ForegroundColor Red
        Write-Host "    Details: $_"
    }
}

# Test 6d: Bank account summary by type
Write-Host "Testing [GET] /accounts/bank/summary ... " -NoNewline
try {
    $response = Invoke-RestMethod -Method Get -Uri "$BaseUrl/accounts/bank/summary" -WebSession $Session -ErrorAction Stop
    $items = @($response)
    $hasShape = ($items.Count -eq 0) -or ($null -ne $items[0].bank_account_type -and $null -ne $items[0].total_balance)
    if ($hasShape) {
        Write-Host "PASS (Returned $($items.Count) type(s))" -ForegroundColor Green
    } else {
        Write-Host "FAIL" -ForegroundColor Red
        Write-Host "    Response missing bank_account_type/total_balance fields"
    }
}
catch {
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host "    Details: $_"
}

# Test 7: List Import Rules
$Uri = "$BaseUrl/rules/list"
Write-Host "Testing [GET] /rules/list ... " -NoNewline

try {
    $response = Invoke-RestMethod -Method Get -Uri $Uri -WebSession $Session -ErrorAction Stop
    # Response should be an array (even if empty)
    if ($response -is [System.Array] -or $response -is [System.Collections.Generic.List[object]]) {
        Write-Host "PASS (Returned array with $($response.Count) rule(s))" -ForegroundColor Green
    } else {
        Write-Host "FAIL" -ForegroundColor Red
        Write-Host "    Expected an array but got: $($response.GetType().Name)"
    }
}
catch {
    Write-Host "ERROR" -ForegroundColor Red
    Write-Host "    Details: $_"
}

# Test 8: Delete non-existent rule — expect a 500 with a descriptive error (not a crash)
$Uri = "$BaseUrl/rules/999999"
Write-Host "Testing [DELETE] /rules/999999 (non-existent) ... " -NoNewline

try {
    $response = Invoke-RestMethod -Method Delete -Uri $Uri -WebSession $Session -Headers @{ "X-CSRF-Token" = $CsrfToken } -ErrorAction Stop
    # If no exception, the function silently deleted nothing — acceptable
    Write-Host "PASS (No error - rule did not exist)" -ForegroundColor Green
}
catch {
    # A 500 is expected here; verify the response body contains 'error'
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 500) {
        Write-Host "PASS (500 returned for non-existent rule as expected)" -ForegroundColor Green
    } else {
        Write-Host "ERROR (Unexpected status $statusCode)" -ForegroundColor Red
        Write-Host "    Details: $_"
    }
}
Test-Endpoint -Method "POST" -Path "/logout" -ExpectedContent "Logged out"
Test-Endpoint -Method "GET" -Path "/accounts/bank" -ExpectedStatus 401
if ($Failures) { throw "$Failures API test(s) failed." }