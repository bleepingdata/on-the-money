"""
Script: ImportOFXFile.py
Purpose: Imports OFX (Open Financial Exchange) files into the PostgreSQL database.
Process:
    1. Parses the OFX file using ofxparse (with a regex pre-processor to fix common formatting errors).
    2. Inserts raw transactions into a staging table.
    3. Calls stored procedures to migrate staged data to the main transaction table and apply accounting rules.
"""
import io
import logging
import re
import warnings
import datetime
from argparse import ArgumentParser

import psycopg2
import sqlalchemy as sa
from sqlalchemy import create_engine

# Replaced ofxtools with ofxparse
from ofxparse import OfxParser

# Suppress the BeautifulSoup HTML parser warning
from bs4 import XMLParsedAsHTMLWarning
warnings.filterwarnings('ignore', category=XMLParsedAsHTMLWarning)

logger = logging.getLogger(__name__)

print("File Import started")

# ---------------------------------------------------------
# 1. COMMAND LINE ARGUMENT PARSING
# ---------------------------------------------------------
# Setup the parser to accept database credentials and file details from the command line
parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="ofxfile", required=True,
                    help="the file name of the OFX format file to import", metavar="FILE")
parser.add_argument("-db", "--databasename", dest="databasename", required=True,
                    help="data source name of the database server")
parser.add_argument("-u", "--username", dest="username", required=True,
                    help="username for the database server connection")
parser.add_argument("-p", "--password", dest="password", required=True,
                    help="password for the database server connection")
parser.add_argument("-host", "--host", dest="host", required=False, default='localhost',
                    help="host address for the database server connection")
parser.add_argument("-port", "--port", dest="port", required=False, default=5432,
                    help="port for the database server connection")

# Create a mutually exclusive group: the user must provide EITHER a bank account number OR a description, not both
bankaccountargs = parser.add_mutually_exclusive_group()
bankaccountargs.add_argument("-ban", "--bankaccountnumber", dest="bankaccountnumber", required=False,
                     help="load transactions into specified bank account")
bankaccountargs.add_argument("-bad", "--bankaccountdescription", dest="bankaccountdescription", required=False,
                    help="load transactions into specified bank account")

args = parser.parse_args()

# Map the parsed arguments to local variables for easier use
s_ofxfile = args.ofxfile
s_databasename = args.databasename
s_username = args.username
s_password = args.password
s_host = args.host
n_port = args.port
s_bank_account_number = args.bankaccountnumber
s_bank_account_friendly_name = args.bankaccountdescription

print("File is %s" % (s_ofxfile))

# ---------------------------------------------------------
# 2. DATABASE INITIALIZATION
# ---------------------------------------------------------
print("Connecting to DB for Prepare")

# Establish a single database connection to be used throughout the script
conn = psycopg2.connect(database=s_databasename, user=s_username, password=s_password, host=s_host, port=n_port)
cur = conn.cursor()

# Retrieve the internal database ID for the specified bank account
cur.execute("select * from books.get_bank_account_id (%s, %s)", (s_bank_account_number, s_bank_account_friendly_name))
row = cur.fetchone()
n_bank_account_id = row[0]
conn.commit()

# Run preparation stored procedure
cur.execute("select * from load.prepare_ofx (%s)", [n_bank_account_id])
conn.commit()

# ---------------------------------------------------------
# 3. OFX PARSING (Using ofxparse with pre-processing)
# ---------------------------------------------------------
# Read the raw OFX file
with open(s_ofxfile, 'rb') as f:
    raw_ofx = f.read()

# Decode to a string so we can manipulate it
ofx_str = raw_ofx.decode('utf-8', errors='ignore')

# Fix the "Empty transaction name" error.
# This regex looks for a <NAME> tag that is immediately followed by another tag 
# (meaning it's empty) and inserts "UNKNOWN" so ofxparse doesn't crash.
ofx_str = re.sub(r'<NAME>\s*(?=<)', r'<NAME>UNKNOWN', ofx_str)

# Convert the cleaned string back into a file-like binary object for ofxparse
cleaned_ofx_file = io.BytesIO(ofx_str.encode('utf-8'))

# Parse the cleaned file
ofx = OfxParser.parse(cleaned_ofx_file)

# Extract account-level information
account = ofx.account
s_bankid = account.routing_number  # Bank ID / Routing Number
s_acctid = account.account_id      # Account ID
s_accttype = account.account_type  # Returns the string type, not the integer enum
s_branchid = account.branch_id     # Branch ID

# Extract the list of transactions from the parsed statement
transactions = account.statement.transactions

# ---------------------------------------------------------
# 4. TRANSACTION INSERTION
# ---------------------------------------------------------
# Loop through each transaction in the OFX file and insert it into the staging table
for transaction in transactions:
    # ofxparse returns tx.date as a datetime object; .date() isolates just the date
    dt_dtposted = transaction.date.date()
    
    # Execute the insert function, mapping ofxparse properties to the expected arguments
    # Note: Mapping .type -> type, .amount -> amount, .id -> fitid, .payee -> name
    cur.execute("select load.insert_ofx_transaction(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
        (n_bank_account_id,
        datetime.datetime.now().date(),
        0,
        s_bankid,
        s_branchid,
        s_acctid,
        s_accttype,
        transaction.type,         # ofxparse uses .type instead of .trntype
        dt_dtposted,
        transaction.amount,       # ofxparse uses .amount instead of .trnamt
        transaction.id,           # ofxparse uses .id instead of .fitid
        transaction.payee,        # ofxparse uses .payee instead of .name
        transaction.memo))

# Commit all transaction inserts to the database
conn.commit()

# ---------------------------------------------------------
# 5. POST-PROCESSING AND GENERAL LEDGER UPDATES
# ---------------------------------------------------------
# Process the inserted OFX transactions into actual bank transactions
cur.execute("select bank.insert_bank_transaction_from_ofx (%s)", [n_bank_account_id])
row = cur.fetchone()
n_import_identifier = row[0]
conn.commit()

# Apply any automated import rules (e.g., auto-categorizing based on payee)
cur.execute("select bank.process_import_rules_from_bank_import (%s)", (n_import_identifier,))
conn.commit()

# Insert the categorized transactions into the General Ledger (GL)
cur.execute("select books.insert_gl_from_bank_import (%s)", [n_import_identifier])
conn.commit()

# Cleanly close the database connection
cur.close()
conn.close()

print("File Import completed successfully")