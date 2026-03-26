
drop table if exists fact_tbl.account_summary_by_month;

drop table if exists books.general_ledger;

drop table if exists bank.transaction;

drop table if exists bank.import_rule_gl_matrix;
drop table if exists bank.import_rule_fields_to_match;
drop table if exists bank.import_rule;

drop table if exists dimension.dates;

drop table if exists load.anz_excel;
drop table if exists load.anz_mortgage_excel;
drop table if exists load.ofx;

drop table if exists bank.bank_account_gl_account_link;

drop table if exists bank.account_debt_type;

drop table if exists books.account;
drop table if exists books.account_type;

drop table if exists bank.account;
drop table if exists bank.account_type;
drop table if exists bank.debt_type;
drop table if exists bank.import_rule_type;

drop schema if exists bank;
drop schema if exists books;
drop schema if exists dimension;
drop schema if exists fact;
drop schema if exists fact_tbl;
drop schema if exists load;

