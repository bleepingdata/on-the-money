
DROP TABLE IF EXISTS fact_tbl.account_summary_by_month;

DROP TABLE IF EXISTS books.general_ledger;

DROP TABLE IF EXISTS bank.transaction;

DROP TABLE IF EXISTS bank.import_rule_gl_matrix;
DROP TABLE IF EXISTS bank.import_rule_fields_to_match;
DROP TABLE IF EXISTS bank.import_rule;

DROP TABLE IF EXISTS dimension.dates;

DROP TABLE IF EXISTS load.anz_excel;
DROP TABLE IF EXISTS load.anz_mortgage_excel;
DROP TABLE IF EXISTS load.ofx;

DROP TABLE IF EXISTS bank.bank_account_gl_account_link;

DROP TABLE IF EXISTS bank.account_debt_type;

DROP TABLE IF EXISTS books.account;
DROP TABLE IF EXISTS books.account_type;

DROP TABLE IF EXISTS bank.account;
DROP TABLE IF EXISTS bank.account_type;
DROP TABLE IF EXISTS bank.debt_type;
DROP TABLE IF EXISTS bank.import_rule_type;

DROP SCHEMA IF EXISTS bank;
DROP SCHEMA IF EXISTS books;
DROP SCHEMA IF EXISTS dimension;
DROP SCHEMA IF EXISTS fact;
DROP SCHEMA IF EXISTS fact_tbl;
DROP SCHEMA IF EXISTS load;

