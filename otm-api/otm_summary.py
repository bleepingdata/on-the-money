"""
Module: otm_summary
Purpose: Helper functions for triggering database summary recalculations used by the OTM Flask API.
"""
import logging

import psycopg2

logger = logging.getLogger(__name__)


def populate_account_summary_by_month(conn: psycopg2.extensions.connection) -> None:
    """
    Trigger recalculation of the fact.account_summary_by_month table.

    Calls the fact_tbl.populate_account_summary_by_month stored procedure, which
    truncates and repopulates the summary fact table from the current GL entries.

    Args:
        conn (psycopg2.extensions.connection): Active psycopg2 database connection.

    Returns:
        None

    Raises:
        psycopg2.DatabaseError: If the stored procedure call or commit fails.

    Example:
        >>> import psycopg2
        >>> conn = psycopg2.connect(database="otm", user="app", password="secret", host="localhost", port=5432)
        >>> populate_account_summary_by_month(conn)
    """
    cur = conn.cursor()
    cur.execute("SELECT fact_tbl.populate_account_summary_by_month()")
    conn.commit()
