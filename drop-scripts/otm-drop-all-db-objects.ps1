# Requires pgpass.conf file in C:\Users\<username>\AppData\Roaming\postgresql, in format host:port:*:username:password
Param([Parameter(Mandatory=$true)]
    $dbname)

    Write-Output $dbname
# database
# psql --host=192.168.20.20 --port=32769 --username=otmadmin -f ..\..\on-the-money\sql\database\create-database.sql

# schema
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f .\database\drop-views.sql

# tables
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f .\database\drop-functions.sql

# sequences
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f .\database\drop-other-objects.sql

# views
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f .\database\drop-tables-and-schema.sql
