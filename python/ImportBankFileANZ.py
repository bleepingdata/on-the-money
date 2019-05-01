import pandas as pd
import psycopg2
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

import argparse
from argparse import ArgumentParser
#import os.path


print ("File Import started")

parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="bankexcelfile", required=True,
                    help="the file name of the ANZ excel file to import", metavar="FILE")
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
s_bankexcelfile = args.bankexcelfile
s_databasename = args.databasename
s_username = args.username
s_password = args.password
s_host = args.host
n_port = args.port
s_bank_account_number = args.bankaccountnumber
s_bank_account_friendly_name = args.bankaccountdescription
b_removeoverlappingtransactions = True
 
print ("File is %s" %(s_bankexcelfile))

 # Connect to DB
print ("Connecting to DB for Prepare")
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)

cur = conn.cursor()

# Get ready for import (truncate load tables, etc)
cur.execute("select load.prepare_anz_excel (%s, %s);", (s_bank_account_number, s_bank_account_friendly_name))
conn.commit()
conn.close()
print ("Committed and closed")

# Check file exists
try:
    with open(args.bankexcelfile) as file:
        pass
except IOError as e:
    print("Unable to open file") #Does not exist OR no read permissions
    raise


# Create the SQLconnection object (postgresql://username:password@host:port/database)
s_alchemy_connection = "postgresql://{}:{}@{}:{}/{}".format(s_username, s_password, s_host, n_port, s_databasename)
engine = create_engine(s_alchemy_connection)

# Load spreadsheet
print ("Loading Excel into data frame")
xl = pd.ExcelFile(s_bankexcelfile)
dfTransactions = xl.parse('Transactions',converters={'Amount':str,'Balance':str})
dfTransactions['bank_account_number'] = s_bank_account_number
dfTransactions['bank_account_friendly_name'] = s_bank_account_friendly_name

print ("Complete")

# # Load a sheet from the spreadsheet into a DataFrame. For ANZ, the sheet we need is named "Transactions"

print ("Inserting data frame into load table")
dfTransactions.to_sql(name='anz_excel', if_exists='append',con=engine, schema='load', index=False, chunksize=1)
print ("Complete")

# # Process the file
print ("Connecting to DB for processing")
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)
cur = conn.cursor()
cur.execute("select bank.insert_bank_transaction_from_anz_excel (%s, %s)", (s_bank_account_number, s_bank_account_friendly_name))
row = cur.fetchone()
n_import_identifier=row[0]

cur.execute("select bank.process_import_rules ()")

cur.execute("select books.insert_gl_from_bank_import (%s)", (n_import_identifier,))

# close the communication with the PostgreSQL database server
cur.close()
conn.commit()

conn.close()
print ("Committed and closed")

print ("File Import complete")