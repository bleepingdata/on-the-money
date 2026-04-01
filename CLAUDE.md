# On The Money — Project Instructions

**On The Money** is a personal finance / bookkeeping application backed by a PostgreSQL database, with a Python/Flask API (`otm-api/otm-api.py`) and PowerShell tooling for database management.

## Project Layout

| Path | Purpose |
|------|---------|
| `otm-api/otm-api.py` | Flask API (all routes live here) |
| `otm-api/templates/` | Jinja2 HTML templates |
| `python/` | Standalone import scripts |
| `sql/` | All CREATE scripts (functions, tables, views, sequences, schema) |
| `drop-scripts/database/` | DROP scripts, executed in dependency order |
| `initialisation/database-init.ps1` | Runs all CREATE scripts in order at setup time |
| `test/test-api.ps1` | API integration tests (PowerShell + `Invoke-RestMethod`) |

## Critical Rules

### 1 — API Tests Are Mandatory
Every new or modified route in `otm-api/otm-api.py` **must** have a matching test case added or updated in `test/test-api.ps1`. Use the `Test-Endpoint` helper already defined in that file.

```powershell
$Payload = @{ key = "value" } | ConvertTo-Json
Test-Endpoint -Method "POST" -Path "/your/new/endpoint" -Body $Payload -ExpectedContent "Success Message"
```

### 2 — PostgreSQL Type Casting in Python
When calling stored procedures via `psycopg2`, always use explicit type casts in the SQL string (e.g. `::varchar`, `::int`) to prevent parameters being passed as `unknown`.

### 3 — Database Init Sync
Any time a database object is created, renamed, or deleted under `sql/`, review and update `initialisation/database-init.ps1` in the same change. A change is incomplete if the init script references deleted objects or omits newly required ones.

### 4 — Drop Script Sync
Any time a database object is created, renamed, or deleted under `sql/`, update the appropriate file in `drop-scripts/database/`:

| Drop file | Object types |
|-----------|-------------|
| `drop-views.sql` | Views (first — depend on tables) |
| `drop-functions.sql` | Functions |
| `drop-other-objects.sql` | Sequences |
| `drop-tables-and-schema.sql` | Tables and schemas (last) |

A change is incomplete if the drop scripts do not reflect the new database state.
