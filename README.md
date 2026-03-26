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

Use [initialisation/database-init.ps1](initialisation/database-init.ps1) as the primary setup entry point. It applies the repository SQL in the expected order:

1. Database creation
2. Schema creation
3. Table creation
4. Sequence creation
5. View creation
6. Function creation
7. Default account data
8. Default import rules

The script accepts these optional parameters:

- `-hostname` default `localhost`
- `-port` default `5432`
- `-username` default `postgres`
- `-dbname` default `onthemoney`

The script expects PostgreSQL credentials to be available via `pgpass.conf`, as noted in [initialisation/database-init.ps1](initialisation/database-init.ps1).

Example:

```powershell
./initialisation/database-init.ps1 -hostname localhost -port 5432 -username postgres -dbname onthemoney
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

If you plan to use the Flask API, create a local `connection_strings.py` file for [otm-api/otm-api.py](otm-api/otm-api.py). That module is expected to define:

- `s_databasename`
- `s_username`
- `s_password`
- `s_host`
- `n_port`

## Usage

### Importing data

Run the Python scripts in the `python/` directory. All scripts accept database credentials and file paths as arguments.

Common arguments:

- `-f`, `--file`: Path to the file to import
- `-db`: Database name
- `-u`: Database username
- `-p`: Database password
- `-host`: Database host, default `localhost`
- `-port`: Database port, default `5432`
- `-ban`: Bank account number
- `-bad`: Bank account description

Use either `-ban` or `-bad` to identify the target bank account.

Example ANZ Excel import:

```bash
python python/ImportBankFileANZ.py -f "path/to/statement.xls" -db "dbname" -u "user" -p "pass" -bad "Account Name"
```

Example OFX import:

```bash
python python/ImportOFXFile.py -f "path/to/export.ofx" -db "dbname" -u "user" -p "pass" -bad "Account Name"
```

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
