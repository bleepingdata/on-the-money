import pandas as pd
#import pyodbc
import psycopg2
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

import argparse
from argparse import ArgumentParser
import os.path

parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="bankexcelfile", required=True,
                    help="the file name of the ANZ excel file to import", metavar="FILE")
parser.add_argument("-db", "--databasename", dest="databasename", required=True,
                    help="data source name of the database server")
parser.add_argument("-u", "--username", dest="username", required=True,
                    help="username for the database server connection")
parser.add_argument("-p", "--password", dest="password", required=True,
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
s_bankaccountnumber = args.bankaccountnumber
s_bankaccountdescription = args.bankaccountdescription
b_removeoverlappingtransactions = True
 
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = "localhost", port = "5432")
print ("Opened database successfully")

cur = conn.cursor()

cur.execute("select BOOKS.PrepareForImportFile (NULL,'Current Account');")
conn.commit

conn.close()

try:
    with open(args.bankexcelfile) as file:
        pass
except IOError as e:
    print("Unable to open file") #Does not exist OR no read permissions
    raise


# # Create the SQLconnection object

# # Connection From Windows

engine = create_engine('postgresql://postgres:lilian99@localhost:5432/onthemoney')
# engine = create_engine('mssql://LOCALHOST\\SQLEXPRESS/OnTheMoney?trusted_connection=yes;driver=SQL+Server+Native+Client+10.0') 

#Connection From MacOS using FreeTDS and unixODBC https://github.com/mkleehammer/pyodbc/wiki/Connecting-to-SQL-Server-from-Mac-OSX
# pyodbc_connection='mssql+pyodbc://{}:{}@{}'.format(username, password, datasourcename)
# engine = create_engine(pyodbc_connection) 

# # Grab a pyodbc cursor to use for calling stored procs
# cursor = engine.raw_connection().cursor()

# # Prepare for the import (this truncates a table and checks if accounts exists)
#cursor.execute("BOOKS.PrepareForImportFile ?, ?", [bankaccountnumber, bankaccountdescription])
#cursor.commit()

# # Load spreadsheet
xl = pd.ExcelFile(s_bankexcelfile)

# # Load a sheet from the spreadsheet into a DataFrame. For ANZ, the sheet we need is named "Transactions"
dfTransactions = xl.parse('Transactions',converters={'Amount':str,'Balance':str})
dfTransactions.to_sql(name='loadimportfile', if_exists='append',con=engine, schema='books', index=False, chunksize=1)

# # Process the file
conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = "localhost", port = "5432")
print ("Opened database successfully")

cur = conn.cursor()
cur.execute("select books.ProcessImportFile (%s, %s, %s)", (s_bankaccountnumber, s_bankaccountdescription, b_removeoverlappingtransactions))
conn.commit

conn.close()