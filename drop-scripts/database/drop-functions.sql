DROP FUNCTION IF EXISTS bank.delete_bank_transaction_entries_for_account;
DROP FUNCTION IF EXISTS bank.delete_import_rule;
DROP FUNCTION IF EXISTS bank.get_bank_account_descriptions;
DROP FUNCTION IF EXISTS bank.get_import_rules;
DROP FUNCTION IF EXISTS bank.insert_bank_transaction_from_anz_excel;
DROP FUNCTION IF EXISTS bank.insert_bank_transaction_from_anz_mortgage_excel;
DROP FUNCTION IF EXISTS bank.insert_bank_transaction_from_ofx;
DROP FUNCTION IF EXISTS bank.insert_import_rule;
DROP FUNCTION IF EXISTS bank.insert_import_rule_fields_to_match;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_asset_purchase;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_loan_drawdown;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_loan_repayment;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_loan_interest;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_interest_only_loan_repayment;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_income;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_expense;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_transfer_out;
DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_transfer_in;
DROP FUNCTION IF EXISTS bank.insert_import_rule_ofx;
DROP FUNCTION IF EXISTS bank.insert_import_rule_wildcard;
DROP FUNCTION IF EXISTS bank.insert_import_rule_type_only;
DROP FUNCTION IF EXISTS bank.process_import_rules_for_transaction;
DROP FUNCTION IF EXISTS bank.process_import_rules_from_bank_import;
DROP FUNCTION IF EXISTS bank.purge_bank_import_from_everywhere;

DROP FUNCTION IF EXISTS books.calculate_balance;
DROP FUNCTION IF EXISTS books.calculate_balance_all;
DROP FUNCTION IF EXISTS books.cleanstringmoney;
DROP FUNCTION IF EXISTS books.delete_gl_entries_for_account;
DROP FUNCTION IF EXISTS books.get_account_balance_at_date;
DROP FUNCTION IF EXISTS books.get_accounts;
DROP FUNCTION IF EXISTS books.insert_gl_entry_basic;
DROP FUNCTION IF EXISTS books.insert_gl_entry_from_bank_transaction;
DROP FUNCTION IF EXISTS books.insert_gl_from_bank_import;
DROP FUNCTION IF EXISTS books.insert_journal_entry_basic;
DROP FUNCTION IF EXISTS books.insert_manual_entry;
DROP FUNCTION IF EXISTS books.last_day;
DROP FUNCTION IF EXISTS books.get_bank_account_id;
DROP FUNCTION IF EXISTS books.process_month_end_mortgage;

DROP FUNCTION IF EXISTS fact_tbl.populate_account_summary_by_month;

DROP FUNCTION IF EXISTS load.prepare_anz_excel;
DROP FUNCTION IF EXISTS load.prepare_anz_mortgage_excel;
DROP FUNCTION IF EXISTS load.prepare_ofx;
DROP FUNCTION IF EXISTS load.insert_ofx_transaction;

