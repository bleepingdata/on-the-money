# AI Coding Guidelines

This document outlines the coding standards and expectations for AI assistants working on the **On The Money** project.

## API Development

### 1. Testing Requirements
**Rule:** Whenever a new API endpoint (route) is added or modified in `otm-api/otm-api.py`, a corresponding test case **must** be created or updated in `test/test-api.ps1`.

- **Test Location**: `test/test-api.ps1`
- **Test Format**: Use the existing PowerShell `Invoke-RestMethod` pattern.
- **Coverage**: 
  - Verify the HTTP status (implicitly handled by `Invoke-RestMethod` throwing on error).
  - Verify the response payload matches the expected output (JSON message or data structure).

### 2. Database Functions
- When adding Python API methods that call PostgreSQL stored procedures, ensure explicit type casting (e.g., `::varchar`, `::int`) is used in the SQL query string within Python. This prevents `psycopg2` from passing parameters as `unknown` types.

## Example Test Pattern
```powershell
$Payload = @{ key = "value" } | ConvertTo-Json
Test-Endpoint -Method "POST" -Path "/your/new/endpoint" -Body $Payload -ExpectedContent "Success Message"
```