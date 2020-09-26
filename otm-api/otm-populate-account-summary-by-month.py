#otm-populate-account-summary-by-month.py
import psycopg2

import argparse
from argparse import ArgumentParser
#import os.path

def populate_account_summary (conn): 
    cur = conn.cursor()

    cur.execute("select fact_tbl.populate_account_summary_by_month()")


