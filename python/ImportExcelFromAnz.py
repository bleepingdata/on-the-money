import pandas as pd
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

engine = create_engine('mssql://LOCALHOST\\SQLEXPRESS/OnTheMoney?trusted_connection=yes;driver=SQL+Server+Native+Client+10.0') 
# metadata = MetaData()

# users = Table('BOOKS.LoadImportFile', metadata,
#         Column('TransactionDate', String(50)),
#         Column('ProcessedDate', String(50)),
#         Column('Type', String(50)),
#         Column('Details', String(50)),
#         Column('Particulars', String(50)),
#         Column('Code', String(50)),
#         Column('Reference', String(50)),
#         Column('Amount', String(50)),
#         Column('Balance', String(50)),
#         Column('ToFromAccountNumber', String(50)),
#         Column('ConversionCharge', String(50)),
#         Column('ForeignCurrencyAmount', String(50)),
#         )


# pd.read_sql(sa.text('SELECT * FROM BOOKS.[Transaction]'),engine)

# Assign spreadsheet filename to `file`
file = 'C:\\Stephen\\Test\\on-the-money\\ANZTestFileExport.xlsx'

# Load spreadsheet
xl = pd.ExcelFile(file)
# Print the sheet names
print(xl.sheet_names)

# Load a sheet into a DataFrame by name: df1
df1 = xl.parse('Transactions')

df1.to_sql(name='LoadImportFile', if_exists='append',con=engine, schema='BOOKS', index=False, chunksize=1)


#file_location = 'C:\Stephen\Test\on-the-money\ANZ-current-account-2017-01-to-2018-06.xlsx'
#workbook = xlrd.open_workbook(file_location)

#print(workbook.sheet_names)

#sg = "Hello World"
#print(msg)