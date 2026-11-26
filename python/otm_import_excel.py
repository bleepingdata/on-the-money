"""
Module: otm_import_excel
Purpose: Imports one ANZ Excel transaction file (account or mortgage layout) into the PostgreSQL database.
Process:
    1. Truncates the staging table via a stored procedure.
    2. Loads the Excel data into a Pandas DataFrame and inserts it into the staging table using SQLAlchemy.
    3. Calls stored procedures to process transactions, apply rules, and update the General Ledger.
"""
import logging
from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
import psycopg2
from sqlalchemy import create_engine

from otm_environment import EnvironmentSettings

logger = logging.getLogger(__name__)


def import_anz_excel_file(settings: EnvironmentSettings, file_path: Path, bank_account_description: str,
                          mortgage: bool = False) -> None:
    """
    Imports an ANZ Excel file into the given bank account.

    Args:
        settings: Environment connection settings.
        file_path: The Excel file to import (must have a 'Transactions' sheet).
        bank_account_description: bank.account description identifying the target account.
        mortgage: True for the ANZ mortgage layout, False for the standard ANZ account layout.

    Raises:
        Exception: Any file or database error.

    Example:
        >>> import_anz_excel_file(settings, Path("statement.xlsx"), "Tractor Bank Current Account")
    """
    load_table = "anz_mortgage_excel" if mortgage else "anz_excel"

    def connect() -> "psycopg2.extensions.connection":
        return psycopg2.connect(database=settings.database, user=settings.username, password=settings.password,
                                host=settings.host, port=settings.port)

    # Read the file first so a bad file doesn't leave the staging table truncated
    df_transactions = pd.ExcelFile(file_path).parse("Transactions", converters={"Amount": str, "Balance": str})
    df_transactions["bank_account_number"] = None
    df_transactions["bank_account_friendly_name"] = bank_account_description

    conn = connect()
    try:
        cur = conn.cursor()
        if mortgage:
            cur.execute("select load.prepare_anz_mortgage_excel();")
        else:
            cur.execute("select load.prepare_anz_excel (%s, %s);", (None, bank_account_description))
        conn.commit()
    finally:
        conn.close()

    engine = create_engine("postgresql://{}:{}@{}:{}/{}".format(
        quote_plus(settings.username), quote_plus(settings.password), settings.host, settings.port, settings.database))
    # append: the staging table was truncated by the prepare step
    df_transactions.to_sql(name=load_table, if_exists="append", con=engine, schema="load", index=False, chunksize=1)

    conn = connect()
    try:
        cur = conn.cursor()
        cur.execute(f"select bank.insert_bank_transaction_from_{load_table} (%s, %s)", (None, bank_account_description))
        n_import_identifier = cur.fetchone()[0]
        cur.execute("select bank.process_import_rules_from_bank_import (%s)", (n_import_identifier,))
        cur.execute("select books.insert_gl_from_bank_import (%s)", (n_import_identifier,))
        cur.execute("select fact_tbl.populate_account_summary_by_month()")
        conn.commit()
    except Exception:
        conn.rollback()
        logger.exception("Excel import failed for %s", file_path.name)
        raise
    finally:
        conn.close()
