# Requires pgpass.conf file in C:\Users\steph\AppData\Roaming\postgresql, in format host:port:*:username:password
Param([Parameter(Mandatory=$false)]
    $hostname='localhost',
    [Parameter(Mandatory=$false)]
    $port='5432',
    [Parameter(Mandatory=$false)]
    $username='postgres',
    [Parameter(Mandatory=$false)]
    $dbname='onthemoney')

    Write-Output "host: $hostname, port: $port, username: $username, database: $dbname"

# database
# psql --host=$hostname --port=$port --username=$username -f ..\..\on-the-money\sql\database\create-database.sql

# views
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f .\database\drop-views.sql

# functions
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f .\database\drop-functions.sql

# sequences
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f .\database\drop-other-objects.sql

# tables and schema
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f .\database\drop-tables-and-schema.sql
