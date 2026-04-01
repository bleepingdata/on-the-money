---
description: Rules for adding or modifying API routes in the On The Money project. Apply when creating, editing, or reviewing otm-api/otm-api.py or test/test-api.ps1.
applyTo: "otm-api/otm-api.py,test/test-api.ps1"
---

# On The Money — API Development Rules

## Test Coverage Is Mandatory

Every new or modified route in `otm-api/otm-api.py` **must** have a corresponding test case added or updated in `test/test-api.ps1`.

- **Test file**: `test/test-api.ps1`
- **Pattern**: Use the existing `Test-Endpoint` PowerShell helper.
- **What to assert**: HTTP success (implicit via `Invoke-RestMethod` throwing on error) and that the response payload matches the expected JSON message or data structure.

### Example

```powershell
$Payload = @{ key = "value" } | ConvertTo-Json
Test-Endpoint -Method "POST" -Path "/your/new/endpoint" -Body $Payload -ExpectedContent "Success Message"
```

A PR or change that adds a route without a test is **incomplete**.

## PostgreSQL Type Casting

When Python code calls a PostgreSQL stored procedure via `psycopg2`, always include explicit type casts in the SQL string:

```python
cur.execute("SELECT bank.my_function(%s::varchar, %s::int)", (name, amount))
```

This prevents `psycopg2` from binding parameters as the `unknown` type, which causes stored procedure resolution failures.
