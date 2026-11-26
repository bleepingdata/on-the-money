"""
Module: otm_import_ofx
Purpose: Imports one OFX (Open Financial Exchange) file into the PostgreSQL database.
Process:
    1. Parses the OFX file using ofxparse (with a regex pre-processor to fix common formatting errors).
    2. Inserts raw transactions into a staging table.
    3. Calls stored procedures to migrate staged data to the main transaction table and apply accounting rules.
"""
import datetime
import io
import logging
import re
import warnings
from pathlib import Path

import psycopg2
from bs4 import XMLParsedAsHTMLWarning
from ofxparse import OfxParser

from otm_environment import EnvironmentSettings

warnings.filterwarnings("ignore", category=XMLParsedAsHTMLWarning)

logger = logging.getLogger(__name__)


def import_ofx_file(settings: EnvironmentSettings, file_path: Path, bank_account_description: str) -> None:
    """
    Imports an OFX file into the given bank account.

    Args:
        settings: Environment connection settings.
        file_path: The OFX file to import.
        bank_account_description: bank.account description identifying the target account.

    Raises:
        Exception: Any parse or database error; the transaction is rolled back.

    Example:
        >>> import_ofx_file(settings, Path("export.ofx"), "Tractor Bank Current Account")
    """
    ofx_str = file_path.read_bytes().decode("utf-8", errors="ignore")
    # An empty <NAME> tag crashes ofxparse, so give it a placeholder value
    ofx_str = re.sub(r"<NAME>\s*(?=<)", r"<NAME>UNKNOWN", ofx_str)
    account = OfxParser.parse(io.BytesIO(ofx_str.encode("utf-8"))).account

    conn = psycopg2.connect(database=settings.database, user=settings.username, password=settings.password,
                            host=settings.host, port=settings.port)
    try:
        cur = conn.cursor()
        cur.execute("select * from books.get_bank_account_id (%s, %s)", (None, bank_account_description))
        n_bank_account_id = cur.fetchone()[0]
        cur.execute("select * from load.prepare_ofx (%s)", [n_bank_account_id])

        for transaction in account.statement.transactions:
            cur.execute(
                "select load.insert_ofx_transaction(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (n_bank_account_id,
                 datetime.datetime.now().date(),
                 0,
                 account.routing_number,
                 account.branch_id,
                 account.account_id,
                 account.account_type,
                 transaction.type,
                 transaction.date.date(),
                 transaction.amount,
                 transaction.id,
                 transaction.payee,
                 transaction.memo))

        cur.execute("select bank.insert_bank_transaction_from_ofx (%s)", [n_bank_account_id])
        n_import_identifier = cur.fetchone()[0]
        cur.execute("select bank.process_import_rules_from_bank_import (%s)", (n_import_identifier,))
        cur.execute("select books.insert_gl_from_bank_import (%s)", [n_import_identifier])
        conn.commit()
    except Exception:
        conn.rollback()
        logger.exception("OFX import failed for %s", file_path.name)
        raise
    finally:
        conn.close()
