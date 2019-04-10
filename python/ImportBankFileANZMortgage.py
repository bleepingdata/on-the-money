import pandas as pd
import psycopg2
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

import argparse
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="anzexcelmortgagefile", required=True,
                    help="the file name of the ANZ excel mortgage file to import", metavar="FILE")
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
s_anzexcelmortgagefile = args.anzexcelmortgagefile
s_databasename = args.databasename
s_username = args.username
s_password = args.password
s_host = args.host
n_port = args.port
s_bankaccountnumber = args.bankaccountnumber
s_bankaccountdescription = args.bankaccountdescription
b_removeoverlappingtransactions = True

 
print ("File is %s" %(s_bankexcelfile))

 # Connect to DB
print ("Connecting to DB for Prepare")
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)

cur = conn.cursor()

# Get ready for import (truncate load tables, etc)
cur.execute("select books.prepare_import (%s, %s);", (s_bankaccountnumber, s_bankaccountdescription))
conn.commit()
conn.close()
print ("Committed and closed")


# # Create the SQL connection object
# pyodbc_connection='mssql+pyodbc://{}:{}@{}'.format(username, password, datasourcename)
# engine = create_engine(pyodbc_connection) 

# # Grab a pyodbc cursor to use for calling stored procs
# cursor = engine.raw_connection().cursor()

# # Prepare for the import (this truncates a table and checks if accounts exists)
# cursor.execute("BOOKS.PrepareForImportFile ?, ?", [bankaccountnumber, bankaccountdescription])
# cursor.commit()

# # Load spreadsheet
# xl = pd.ExcelFile(bankexcelfile)

# # Load a sheet from the spreadsheet into a DataFrame. For ANZ, the sheet we need is named "Transactions"
# dfTransactions = xl.parse('Transactions',converters={'Amount':str,'Balance':str})
# dfTransactions.to_sql(name='LoadImportFile_Excel_ANZMortgage', if_exists='append',con=engine, schema='BOOKS', index=False, chunksize=1)

# # Process the file
# cursor.execute("BOOKS.ProcessImportFile_Excel_ANZMortgage ?, ?, ?", [bankaccountnumber, bankaccountdescription, removeoverlappingtransactions])
# cursor.commit()


