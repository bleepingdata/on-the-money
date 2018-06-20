import pandas as pd
import pyodbc
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

import argparse
from argparse import ArgumentParser
import os.path

parser = ArgumentParser()
bankaccountargs = parser.add_mutually_exclusive_group()
parser.add_argument("-f", "--file", dest="bankexcelfile", required=True,
                    help="the file name of the ANZ excel file to import", metavar="FILE")
bankaccountargs.add_argument("-ban", "--bankaccountnumber", dest="bankaccountnumber", required=False,
                    help="load transactions into specified bank account")
bankaccountargs.add_argument("-bad", "--bankaccountdescription", dest="bankaccountdescription", required=False,
                    help="load transactions into specified bank account")
args = parser.parse_args()

try:
    with open(args.bankexcelfile) as file:
        pass
except IOError as e:
    print("Unable to open file") #Does not exist OR no read permissions
    raise

# Set parameter-related variables
bankexcelfile = args.bankexcelfile
bankaccountnumber = args.bankaccountnumber
bankaccountdescription = args.bankaccountdescription
removeoverlappingtransactions = True; 

# Create the SQL connection object
engine = create_engine('mssql://LOCALHOST\\SQLEXPRESS/OnTheMoney?trusted_connection=yes;driver=SQL+Server+Native+Client+10.0') 

# Grab a pyodbc cursor to use for calling stored procs
cursor = engine.raw_connection().cursor()

# Prepare for the import (this truncates a table and checks if accounts exists)
cursor.execute("BOOKS.PrepareForImportFile ?, ?", [bankaccountnumber, bankaccountdescription])
cursor.commit()

# Load spreadsheet
xl = pd.ExcelFile(bankexcelfile)

# Load a sheet from the spreadsheet into a DataFrame. For ANZ, the sheet we need is named "Transactions"
dfTransactions = xl.parse('Transactions',converters={'Amount':str,'Balance':str})
dfTransactions.to_sql(name='LoadImportFile', if_exists='append',con=engine, schema='BOOKS', index=False, chunksize=1)

# Process the file
cursor.execute("BOOKS.ProcessImportFile ?, ?, ?", [bankaccountnumber, bankaccountdescription, removeoverlappingtransactions])
cursor.commit()


