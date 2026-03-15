import pandas as pd
import psycopg2
import datetime
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

from ofxtools.Parser import OFXTree

import argparse
from argparse import ArgumentParser

print ("File Import started")

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
s_ofxfile = args.ofxfile
s_databasename = args.databasename
s_username = args.username
s_password = args.password
s_host = args.host
n_port = args.port
s_bank_account_number = args.bankaccountnumber
s_bank_account_friendly_name = args.bankaccountdescription


print ("File is %s" %(s_ofxfile))

 # Connect to DB
print ("Connecting to DB for Prepare")
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)
cur = conn.cursor()
cur.execute("select * from books.get_bank_account_id (%s, %s)", (s_bank_account_number, s_bank_account_friendly_name))
row = cur.fetchone()
n_bank_account_id=row[0]
conn.commit()
cur.execute("select * from load.prepare_ofx (%s)", [n_bank_account_id])
conn.commit()

parser = OFXTree()

with open(s_ofxfile, 'rb') as f:  # N.B. need to open file in binary mode
    parser.parse(f)

ofx = parser.convert()

stmts = ofx.statements 
txs = stmts[0].transactions 

acct = stmts[0].account

s_bankid = acct.bankid
s_acctid = acct.acctid
s_accttype = acct.accttype
s_branchid = acct.branchid

conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)
cur = conn.cursor()

for tx in txs:
    dt_dtposted = tx.dtposted.date()
    cur.execute("select load.insert_ofx_transaction(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", 
        (n_bank_account_id,
        datetime.datetime.now().date(),
		0,
		s_bankid,
		s_branchid,
		s_acctid,
		s_accttype,
		tx.trntype,
		dt_dtposted,
		tx.trnamt,
		tx.fitid,
		tx.name,
		tx.memo))

    
conn.commit()

# # Process the file
cur.execute("select bank.insert_bank_transaction_from_ofx (%s)", [n_bank_account_id])
row = cur.fetchone()
n_import_identifier=row[0]
conn.commit()

cur.execute("select bank.process_import_rules_from_bank_import (%s)", (n_import_identifier,))
conn.commit()

cur.execute("select books.insert_gl_from_bank_import (%s)", [n_import_identifier])
conn.commit()

conn.close()




