
drop table fact.account_summary_by_month;

drop table books.general_ledger;

drop table bank.transaction;

drop table bank.import_rule_gl_matrix;
drop table bank.import_rule_fields_to_match;
drop table bank.import_rule;

drop table dimension.dates;

drop table load.anz_excel;
drop table load.anz_mortgage_excel;
DROP TABLE load.ofx;

drop table bank.bank_account_gl_account_link;

drop table bank.account_debt_type;

drop table books.account;
drop table books.account_type;

drop table bank.account;
drop table bank.account_type;
drop table bank.debt_type;
DROP TABLE bank.import_rule_type;

drop schema bank;
drop schema books;
drop schema dimension;
drop schema fact;
drop schema load;

