# on-the-money

A home accounting database for personal banking analysis. Designed for use with ANZ and Kiwibank export files.

## Features

- **Data Import**: Python scripts to import banking files (Excel, OFX) into a PostgreSQL database.
- **Categorization**: Automated rule-based categorization of transactions.
- **Reporting**: Summary views for reporting and visualization (monthly summaries).
- **API**: Basic Flask API for triggering summaries.

## Supported Formats

- **ANZ**: Excel (`.xls` / `.xlsx`), OFX
- **Kiwibank**: OFX

## Prerequisites

- **Python**: 3.6+
- **PostgreSQL**: 10.4+
- **Python Packages**:
    - `pandas`
    - `psycopg2`
    - `sqlalchemy`
    - `ofxparse`
    - `flask`
    - `argparse`

## Setup

1. **Database Initialization**:
   - Create a PostgreSQL database (e.g., `onthemoney`).
   - Run the SQL scripts located in `sql/tables/` to create the schema and tables.
   - Run the SQL scripts in `sql/functions/` to create the stored procedures.

2. **Configuration**:
   - Ensure you have a `connection_strings.py` file for the API if you plan to use it (see `otm-api/otm-api.py`).

## Usage

### Importing Data

Run the Python scripts located in the `python/` directory. All scripts accept database credentials and file paths as arguments.

**Common Arguments:**
- `-f`, `--file`: Path to the file to import.
- `-db`: Database name.
- `-u`: Database username.
- `-p`: Database password.
- `-host`: Database host (default: localhost).
- `-port`: Database port (default: 5432).
- `-ban`: Bank account number (target account).
- `-bad`: Bank account description (target account friendly name). *Note: Use either -ban or -bad.*

**Example - Import ANZ Excel File:**
```bash
python python/ImportBankFileANZ.py -f "path/to/statement.xls" -db "dbname" -u "user" -p "pass" -bad "Account Name"
```

**Example - Import OFX File:**
```bash
python python/ImportOFXFile.py -f "path/to/export.ofx" -db "dbname" -u "user" -p "pass" -bad "Account Name"
```

### API

A Flask-based API is available in `otm-api/otm-api.py` to trigger account summaries.

```bash
python otm-api/otm-api.py
```

Endpoints:
- `PUT /summary/populate`: Triggers the `populate_account_summary_by_month` stored procedure.

## Project Status

The project is pre-alpha.
Developed using Visual Studio Code and DBeaver on macOS 10.13 / Win 10 using Python 3.6.5 (including Pandas and Anaconda) with Postgres 10.4.

## Future Plans

- **API**: Expand Flask API to wrap Python scripts in a RESTful interface.
- **UI**: Potential development of a frontend.
