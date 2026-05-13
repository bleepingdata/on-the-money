"""
Script: ImportBankFileANZMortgage.py
Purpose: Imports ANZ Mortgage transaction data from an Excel file into the PostgreSQL database.
Process:
    1. Truncates the staging table via a stored procedure.
    2. Loads Excel data into a Pandas DataFrame and inserts it into the staging table using SQLAlchemy.
    3. Calls stored procedures to process transactions, apply rules, and update the General Ledger.
"""
import logging

import pandas as pd
import psycopg2
import sqlalchemy as sa
from sqlalchemy import create_engine
from argparse import ArgumentParser

logger = logging.getLogger(__name__)

print ("File Import started")

# ---------------------------------------------------------
# 1. COMMAND LINE ARGUMENT PARSING
# ---------------------------------------------------------
parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="input_file", required=True,
                    help="the file name and path that to import", metavar="FILE")
parser.add_argument("-db", "--databasename", dest="databasename", required=True,
                    help="data source name of the database server")
parser.add_argument("-u", "--username", dest="username", required=True,
                    help="username for the database server connection")
parser.add_argument("-p", "--password", dest="password", required=True,
                    help="password for the database server connection")
parser.add_argument("-host", "--host", dest="host", required=False, default='localhost',
                    help="password for the database server connection")
parser.add_argument("-port", "--port", dest="port", required=False, default=5432,
                    help="password for the database server connection")
bankaccountargs = parser.add_mutually_exclusive_group()
bankaccountargs.add_argument("-ban", "--bankaccountnumber", dest="bankaccountnumber", required=False,
                     help="load transactions into specified bank account")
bankaccountargs.add_argument("-bad", "--bankaccountdescription", dest="bankaccountdescription", required=False,
                    help="load transactions into specified bank account")
args = parser.parse_args()


# Set parameter-related variables
s_input_file = args.input_file
s_databasename = args.databasename
s_username = args.username
s_password = args.password
s_host = args.host
n_port = args.port
s_bank_account_number = args.bankaccountnumber
s_bank_account_friendly_name = args.bankaccountdescription
b_removeoverlappingtransactions = True
 
print ("File is %s" %(s_input_file))

# ---------------------------------------------------------
# 2. PREPARE STAGING ENVIRONMENT
# ---------------------------------------------------------
print ("Connecting to DB for Prepare")
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)

cur = conn.cursor()

# Get ready for import (truncate load tables, etc)
cur.execute("select load.prepare_anz_mortgage_excel();")
conn.commit()
conn.close()
print ("Committed and closed")

# ---------------------------------------------------------
# 3. LOAD FILE AND INSERT TO STAGING
# ---------------------------------------------------------
try:
    with open(args.input_file) as file:
        pass
except IOError as e:
    print("Unable to open file") #Does not exist OR no read permissions
    raise


# Create the SQLAlchemy connection object (required for pandas to_sql)
s_alchemy_connection = "postgresql://{}:{}@{}:{}/{}".format(s_username, s_password, s_host, n_port, s_databasename)
engine = create_engine(s_alchemy_connection)

# Load spreadsheet
print ("Loading Excel into data frame")
excel_file = pd.ExcelFile(s_input_file)
df_transactions = excel_file.parse('Transactions',converters={'Amount':str,'Balance':str})
df_transactions['bank_account_number'] = s_bank_account_number
df_transactions['bank_account_friendly_name'] = s_bank_account_friendly_name

print ("Complete")

# Insert the DataFrame into the 'anz_mortgage_excel' table in the 'load' schema.
# if_exists='append' is used because we truncated the table in the preparation step.
print ("Inserting data frame into load table")
df_transactions.to_sql(name='anz_mortgage_excel', if_exists='append',con=engine, schema='load', index=False, chunksize=1)
print ("Complete")

# ---------------------------------------------------------
# 4. PROCESS TRANSACTIONS (STORED PROCEDURES)
# ---------------------------------------------------------
print ("Connecting to DB for processing")
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)
cur = conn.cursor()
cur.execute("select bank.insert_bank_transaction_from_anz_mortgage_excel (%s, %s)", (s_bank_account_number, s_bank_account_friendly_name))
row = cur.fetchone()
n_import_identifier=row[0]

conn.commit()
cur.execute("select bank.process_import_rules_from_bank_import (%s)", (n_import_identifier,))
conn.commit()
cur.execute("select books.insert_gl_from_bank_import (%s)", (n_import_identifier,))
conn.commit()
cur.execute("select fact_tbl.populate_account_summary_by_month()")

# close the communication with the PostgreSQL database server
cur.close()
conn.commit()

conn.close()
print ("Committed and closed")

print ("File Import complete")