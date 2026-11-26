# on-the-money

A home accounting database for personal banking analysis. Designed for use with ANZ and Kiwibank export files.

## Features

- **Data Import**: Python scripts to import banking files (Excel, OFX) into a PostgreSQL database.
- **Categorization**: Automated rule-based categorization of transactions.
- **Reporting**: Summary tables and views for month-based reporting.
- **API**: A small Flask API for summary generation and account/rule endpoints.

## Supported Formats

- **ANZ**: Excel (`.xls` / `.xlsx`), OFX
- **Kiwibank**: OFX

## Prerequisites

- **Python**: 3.6+
- **PostgreSQL**: 10.4+
- **PowerShell**: Required for the repository setup and test scripts on Windows.
- **Python packages**:
  - `pandas`
  - `psycopg2`
  - `sqlalchemy`
  - `ofxparse`
  - `flask`
  - `argparse`

## Setup

### Preferred database bootstrap

Use [deploy.ps1](deploy.ps1) as the single setup entry point. It applies the repository SQL in this order:

1. Database creation (if the database does not exist)
2. Schema creation
3. Table creation
4. Sequence creation
5. View creation
6. Function creation
7. Default data (accounts, account types, import rules)
8. Private init scripts for the environment (bank accounts etc., kept outside the repo)

Each SQL folder is run in file-name order, so numeric prefixes control ordering.

Every deploy names an environment: `.\deploy.ps1 -Environment sample_environment`. The name selects two things:

- **Environment file** (local, git-ignored): `environments\*.json` with `name` (what you pass to `-Environment`; defaults to the file name) and `privatePath` (the private folder). Sub-folders are fine. To create one, follow [environments/README.md](environments/README.md).
- **Private folder** (outside the repo, at `privatePath`): holds `connection_strings.py` (the only place database host/port/name/user/password live; also used by the API, copied to `-AppPath`), `init\*.sql`, bank exports and notes.

Parameters:

- `-Environment` **mandatory**; lowercase letters, digits and underscores (e.g. `sample_environment`)
- `-Target` `All` (default), `Python` or `Database`
- `-AppPath` default `C:\otm\src` (Python files only)
- `-SkipDefaultData` skips step 7
- `-SkipPrivateData` skips step 8 (`<privatePath>\init\*.sql`)

The password is requested once (or taken from `PGPASSWORD` if already set). Requires `psql` and PowerShell 7 on the PATH.

#### Private data (kept out of git and away from AI tools)

Run `.\init-environment.ps1 -Environment sample_environment` once to create `~\otm-private\sample_environment` (outside the repo) containing `init\` (psql scripts with your bank details), `bank-exports\` (an incoming folder per mapped bank account; see `bankAccounts` in [environments/README.md](environments/README.md)) and `notes\` (personal markdown). Then copy bank files into an account's incoming folder and run `python python/ImportBankFiles.py -e sample_environment`. Never add this folder to the VS Code workspace.

Example:

```powershell
./deploy.ps1 -Environment sample_environment -Target Database
```

### Manual setup scope

If you do not use the init script, make sure you apply the SQL under these folders in dependency order:

1. `sql/database/`
2. `sql/schema/`
3. `sql/tables/`
4. `sql/sequence/`
5. `sql/views/`
6. `sql/functions/`
7. `sql/default-data/`

### Database Reset for Testing

To reset the test database by dropping all objects and starting fresh:

```powershell
./drop-scripts/otm-drop-all-db-objects.ps1
```

This script drops all database objects in the correct dependency order:
1. All views (via `drop-views.sql`)
2. All functions (via `drop-functions.sql`)
3. All sequences (via `drop-other-objects.sql`)
4. All tables and schemas (via `drop-tables-and-schema.sql`)

After dropping objects, you can re-initialize the database using the setup process described above.

### API configuration

If you plan to use the Flask API, `connection_strings.py` lives in the environment's private folder (`privatePath` in its environments JSON) and is copied next to `otm-api.py` by `deploy.ps1`; `init-environment.ps1` creates a template. It must define:

- `s_databasename`
- `s_username`
- `s_password`
- `s_host`
- `n_port`

## Usage

### Importing data

One script imports all bank files, OFX (`.ofx`, `.qfx`) and ANZ Excel (`.xls`, `.xlsx`): `python/ImportBankFiles.py`. Connection details and the account-to-folder mapping come from the environment (see [environments/README.md](environments/README.md)); you are prompted for the password if it isn't stored in `connection_strings.py`.

```bash
# Import every new file waiting in the incoming folders of all mapped accounts
python python/ImportBankFiles.py -e sample_environment

# Only one account (bank.account description)
python python/ImportBankFiles.py -e sample_environment -a "Tractor Bank Current Account"

# One specific file, e.g. to re-import it from the processed folder (account inferred from its folder, else add -a)
python python/ImportBankFiles.py -e sample_environment -f statement.ofx
```

Each imported file is moved to a `processed` sub-folder of its account's incoming folder. A file named with `-f` is only moved if it is waiting in an incoming folder.

### API

The Flask API entry point is [otm-api/otm-api.py](otm-api/otm-api.py).

```bash
python otm-api/otm-api.py
```

Current routes include:

- `PUT /summary/populate`
- `POST /rules/expense`
- `GET /accounts/bank`
- `GET /accounts/books`

## Testing

Canonical API integration tests are in [test/test-api.ps1](test/test-api.ps1).

Run them after starting the API:

```powershell
./test/test-api.ps1
```

## Project Status

The project is pre-alpha.
Developed using Visual Studio Code and DBeaver on macOS 10.13 / Win 10 using Python 3.6.5 with PostgreSQL 10.4.

## Future Plans

- **API**: Expand the Flask API to cover more of the import and reporting workflow.
- **UI**: Potential development of a frontend.
