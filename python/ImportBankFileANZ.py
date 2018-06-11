import pandas as pd
import sqlalchemy as sa
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, ForeignKey

engine = create_engine('mssql://LOCALHOST\\SQLEXPRESS/OnTheMoney?trusted_connection=yes;driver=SQL+Server+Native+Client+10.0') 


file = 'C:\\Stephen\\Test\\on-the-money\\ANZTestFileExport.xlsx'
# Load spreadsheet
xl = pd.ExcelFile(file)

# Load a sheet into a DataFrame by name: df1
df1 = xl.parse('Transactions')
df1.to_sql(name='LoadImportFile', if_exists='append',con=engine, schema='BOOKS', index=False, chunksize=1)

