# On The Money — Project Instructions

**On The Money** is a personal finance / bookkeeping application backed by a PostgreSQL database, with a Python/Flask API (`otm-api/otm-api.py`) and PowerShell tooling for database management.

## Project Layout

| Path | Purpose |
|------|---------|
| `otm-api/otm-api.py` | Flask API (all routes live here) |
| `otm-api/templates/` | Jinja2 HTML templates (all extend `base.html`, which holds the nav menu) |
| `otm-api/static/` | `css/theme.css` (design tokens — the only place for raw colours/fonts/spacing), `css/app.css` (components built from tokens), `js/app.js` (shared helpers). No inline styles or hard-coded colours in templates |
| `python/` | Standalone import scripts |
| `sql/` | All CREATE scripts (functions, tables, views, sequences, schema) |
| `drop-scripts/database/` | DROP scripts, executed in dependency order |
| `deploy.ps1` | Deploys Python files and runs all CREATE scripts in order (database, schema, tables, sequences, views, functions, default data, then private init scripts) |
| `init-environment.ps1` | Scaffolds an environment's private data folder (including `connection_strings.py`), which lives OUTSIDE the repo |
| `environments/` | Local, git-ignored `*.json` per deploy target: environment `name` + `privatePath` only (connection details live in the private folder's `connection_strings.py`); loaded by `otm-environment.ps1`. `environments/README.md` documents creating one and **must be updated whenever environment config, `init-environment.ps1` or deploy parameters change** |
| `test/test-api.ps1` | API integration tests (PowerShell + `Invoke-RestMethod`) |

## Critical Rules

### 0 — Private Data Is Off-Limits
Sensitive data (bank details, bank files, personal notes) lives in per-environment private folders (located by `privatePath` in the environment's git-ignored `environments/*.json`), outside this repo. Every `deploy.ps1` run requires `-Environment`, which selects that JSON file; connection details and the password are in `connection_strings.py` in the private folder. AI assistants must never read, list, search, copy or run anything from the private folders, and must not echo their contents. Don't ask the user to paste their contents; point them to run `deploy.ps1` / import scripts themselves.

### 1 — API Tests Are Mandatory
Every new or modified route in `otm-api/otm-api.py` **must** have a matching test case added or updated in `test/test-api.ps1`. Use the `Test-Endpoint` helper already defined in that file.

```powershell
$Payload = @{ key = "value" } | ConvertTo-Json
Test-Endpoint -Method "POST" -Path "/your/new/endpoint" -Body $Payload -ExpectedContent "Success Message"
```

### 2 — PostgreSQL Type Casting in Python
When calling stored procedures via `psycopg2`, always use explicit type casts in the SQL string (e.g. `::varchar`, `::int`) to prevent parameters being passed as `unknown`.

### 3 — Database Init Sync
Any time a database object is created, renamed, or deleted under `sql/`, use numeric prefixes where creation order matters. `deploy.ps1` discovers files by folder, so no script list needs updating.

### 4 — Drop Script Sync
Any time a database object is created, renamed, or deleted under `sql/`, update the appropriate file in `drop-scripts/database/`:

| Drop file | Object types |
|-----------|-------------|
| `drop-views.sql` | Views (first — depend on tables) |
| `drop-functions.sql` | Functions |
| `drop-other-objects.sql` | Sequences |
| `drop-tables-and-schema.sql` | Tables and schemas (last) |

A change is incomplete if the drop scripts do not reflect the new database state.
