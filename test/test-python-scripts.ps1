# Requires pgpass.conf file in C:\Users\steph\AppData\Roaming\postgresql, in format host:port:*:username:password
Param([Parameter(Mandatory=$false)]
    $hostname='localhost',
    [Parameter(Mandatory=$false)]
    $port='5432',
    [Parameter(Mandatory=$false)]
    $username='postgres',
    [Parameter(Mandatory=$false)]
    $dbname='onthemoney',
    [Parameter(Mandatory=$true)]
    $password)

    Write-Output "host: $hostname, port: $port, username: $username, database: $dbname"

   
python ..\..\on-the-money\otm-api\otm-populate-account-summary-by-month.py -db $dbname -u $username -p $password -host $hostname -port $port
