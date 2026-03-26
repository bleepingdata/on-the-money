# AI Coding Guidelines

This document outlines the coding standards and expectations for AI assistants working on the **On The Money** project.

## API Development

### 1. Testing Requirements
**Rule:** Whenever a new API endpoint (route) is added or modified in `otm-api/otm-api.py`, a corresponding test case **must** be created or updated in `test/test-api.ps1`.

- **Canonical Test Location**: `test/test-api.ps1`
- **Test Format**: Use the existing PowerShell `Invoke-RestMethod` pattern.
- **Coverage**: 
  - Verify the HTTP status (implicitly handled by `Invoke-RestMethod` throwing on error).
  - Verify the response payload matches the expected output (JSON message or data structure).

### 2. Database Functions
- When adding Python API methods that call PostgreSQL stored procedures, ensure explicit type casting (e.g., `::varchar`, `::int`) is used in the SQL query string within Python. This prevents `psycopg2` from passing parameters as `unknown` types.

### 3. Database Initialization Sync
- Whenever a database object is created, renamed, or deleted, `initialisation/database-init.ps1` must be reviewed and updated in the same change.
- This applies to objects defined under `sql/database/`, `sql/schema/`, `sql/tables/`, `sql/sequence/`, `sql/views/`, `sql/functions/`, and `sql/default-data/` where the initializer loads them directly.
- A change that adds or removes a database object is incomplete if `initialisation/database-init.ps1` still references deleted objects or does not include newly required objects.

### 4. Database Drop Scripts Sync
**Rule:** Whenever a database object (table, view, function, sequence, schema) is created, renamed, or deleted in `sql/database/`, `sql/schema/`, `sql/tables/`, `sql/sequence/`, `sql/views/`, `sql/functions/`, the corresponding drop script in `drop-scripts/database/` **must** be updated in the same change.

- **Drop Script Location**: `drop-scripts/database/`
- **Drop Order**: Maintain the correct dependency order:
  1. `drop-views.sql` (views first, as they depend on tables)
  2. `drop-functions.sql` (functions second)
  3. `drop-other-objects.sql` (sequences third)
  4. `drop-tables-and-schema.sql` (tables and schemas last)
- **When to Update**: Add a DROP statement when creating a new object; remove the DROP statement when deleting an object; add an updated DROP statement when renaming an object.
- A change that adds or removes a database object is incomplete if the drop scripts do not reflect the new database state.

## Example Test Pattern
```powershell
$Payload = @{ key = "value" } | ConvertTo-Json
Test-Endpoint -Method "POST" -Path "/your/new/endpoint" -Body $Payload -ExpectedContent "Success Message"
```