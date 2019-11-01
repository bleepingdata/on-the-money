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

# schema
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\schema\create-schema.sql

# tables
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\tables\create-tables.sql

# sequences
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\sequence\bank.import_identifier.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\sequence\books.general_ledger_group_sequence.sql

# views
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.account.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.account_type.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.months.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\dimension.bank_account.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.account_summary_by_month.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.account_balance.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.account_movement.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.transaction.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.uncategorised_transactions.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.gl_entries.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.bank_transfers.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.cash_balance.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\views\fact.bank_account_balance.sql


#functions
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.delete_bank_transactions_for_account.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_bank_transaction_from_anz_excel.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_bank_transaction_from_anz_mortgage_excel.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_bank_transaction_from_ofx.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_fields_to_match.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_asset_purchase.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_loan_drawdown.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_loan_repayment.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_loan_interest.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_interest_only_loan_repayment.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_transfer_out.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_transfer_in.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_income.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_expense.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_gl_rules_transfer_out.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_ofx.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_type_only.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.insert_import_rule_wildcard.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.process_import_rules_from_bank_import.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.process_import_rules_for_transaction.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\bank.purge_bank_import_from_everywhere.sql

psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.delete_gl_entries_for_account.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.get_account_balance_at_date.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_gl_entry_basic.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_gl_entry_from_bank_transaction.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_gl_from_bank_import.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.insert_journal_entry_basic.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.last_day.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.get_bank_account_id.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\books.process_month_end_mortgage.sql

psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\fact_tbl.populate_account_summary_by_month.sql

psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\load.prepare_anz_excel.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\load.prepare_anz_mortgage_excel.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\load.prepare_ofx.sql
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\functions\load.insert_ofx_transaction.sql

# default accounts
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\default-data\otm-default-accounts.sql

# common rules
psql --host=$hostname --port=$port --username=$username --dbname $dbname -f ..\..\on-the-money\sql\default-data\otm-default-rules.sql