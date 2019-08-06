# Requires pgpass.conf file in C:\Users\steph\AppData\Roaming\postgresql, in format host:port:*:username:password
Param([Parameter(Mandatory=$true)]
    $dbname)

    Write-Output $dbname

# database
# psql --host=192.168.20.20 --port=32769 --username=otmadmin -f ..\..\on-the-money\sql\database\create-database.sql

# schema
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\schema\create-schema.sql

# tables
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\tables\create-tables.sql

# sequences
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\sequence\bank.import_identifier.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\sequence\books.general_ledger_group_sequence.sql

# views
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.account.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.account_type.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.months.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.account_balance.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.account_movement.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.transaction.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.uncategorised_transactions.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.gl_entries.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.bank_transfers.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\views\fact.cash_balance.sql

#functions
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.delete_bank_transactions_for_account.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_bank_transaction_from_anz_excel.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_bank_transaction_from_anz_mortgage_excel.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_bank_transaction_from_ofx.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_ofx.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_type_only.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_wildcard.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.process_import_rules.sql

psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.delete_gl_entries_for_account.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.get_account_balance_at_date.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_gl_entry_basic.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_gl_entry_from_bank_transaction.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_gl_from_bank_import.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_journal_entry_basic.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.last_day.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\books.get_bank_account_id.sql

psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\fact.populate_account_summary_by_month.sql

psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\load.prepare_anz_excel.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\load.prepare_anz_mortgage_excel.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\load.prepare_ofx.sql
psql --host=192.168.20.20 --port=32769 --username=otmadmin --dbname $dbname -f ..\..\on-the-money\sql\functions\load.insert_ofx_transaction.sql
