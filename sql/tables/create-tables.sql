

create table bank.account_type
(
bank_account_type_id smallint generated by default as identity primary key,
description varchar(50) not null constraint uq_books_account_type_description unique
);

insert into bank.account_type(bank_account_type_id, description) values (0, 'unknown account type');
insert into bank.account_type(bank_account_type_id, description) values (1, 'Cash');
insert into bank.account_type(bank_account_type_id, description) values (2, 'Debt');
insert into bank.account_type(bank_account_type_id, description) values (3, 'Credit');

create table bank.debt_type
(
debt_type_id smallint generated by default as identity primary key,
description varchar(50) not null constraint uq_bank_debt_type_description UNIQUE
);

insert into bank.debt_type(debt_type_id, description) values (0, 'unknown debt type');
insert into bank.debt_type(debt_type_id, description) values (1, 'Fixed Rate Mortgage');

create table bank.account
(
bank_account_id int4 generated by default as identity primary key,
bank_account_type_id smallint not null references bank.account_type(bank_account_type_id),
description varchar(50) not null constraint uq_bank_account_description unique,
open_date date not null,
close_date date not null,
external_friendly_name varchar(256) null constraint uq_bank_account_external_friendly_name unique,
external_unique_identifier varchar(56) null constraint uq_bank_account_external_unique_identifier unique
);

create table books.account_type
(
account_type_id smallint generated by default as identity primary key,
description varchar(50) not null constraint uq_books_account_type_description unique
);

insert into books.account_type(account_type_id, description) values (0, 'unknown account type');
insert into books.account_type(account_type_id, description) values (1, 'assets');
insert into books.account_type(account_type_id, description) values (2, 'liabilities');
insert into books.account_type(account_type_id, description) values (3, 'equity');
insert into books.account_type(account_type_id, description) values (4, 'income');
insert into books.account_type(account_type_id, description) values (5, 'expense');

create table books.account
(
account_id int generated by default as identity primary key,
account_type_id smallint not null references books.account_type(account_type_id),
account_code char(10) not null constraint uq_books_account_account_code unique,
description varchar(50) not null constraint uq_books_account_description unique,
open_date date not null,
close_date date not null,
bank_account_id int null references bank.account(bank_account_id)
);

insert into books.account (account_id, account_type_id, account_code, description, open_date, close_date, bank_account_id)
	values (0, 0, '0', 'unknown account', '1900-01-01', '2099-12-31', NULL);
insert into books.account (account_type_id, account_code, description, open_date, close_date, bank_account_id)
	values (4, '40000', 'uncategorised income', '1900-01-01', '2099-12-31', NULL);
insert into books.account (account_type_id, account_code, description, open_date, close_date, bank_account_id)
	values (5, '50000', 'uncategorised expense', '1900-01-01', '2099-12-31', NULL);


create table bank.account_debt_type
(
bank_account_debt_type_id smallint generated by default as identity primary key,
bank_account_id int4 not null references bank.account(bank_account_id),
debt_type_id smallint not null references bank.debt_type(debt_type_id),
principal_account_id int4 NOT NULL REFERENCES books.account(account_id),
interest_payable_account_id int4 NULL REFERENCES books.account(account_id),
pay_interest_payable_first boolean NOT NULL DEFAULT (true)
);

-- a table to link bank accounts to chart of accounts
create table bank.bank_account_gl_account_link
(
bank_account_gl_account_link_id int generated by default as identity primary key,
bank_account_id int not null references bank.account(bank_account_id),
account_id int not null references books.account(account_id),
is_default boolean not null default (true)
);

create table bank.import_rule_type
(
import_rule_type_id smallint generated by default as identity primary key,
description varchar(50),
details varchar(2000)
);

insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (0, 'unknown', 'Unknown Import Rule');
insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (1, 'assets', 'An asset purchase from the bank to an asset account with no transaction splits');
insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (2, 'liabilities', 'A liability increase from the bank with no transaction splits');
insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (3, 'equity', 'A change in equity or bank transfer');
insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (4, 'income', 'An income deposit to the bank with no transaction splits');
insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (5, 'expense', 'An expense withdrawal from the bank to an expense account with no transaction splits');
insert into bank.import_rule_type (import_rule_type_id, description, details)
	values (6, 'loan repayment', 'Splits the bank transaction to two accounts. Pays down a payables account to zero, and puts the remainder against the loan principle');


/* most common import_rule fields */
create table bank.import_rule
(
import_rule_id int4 not null generated by default as identity primary key,
import_rule_type_id int2 not null references bank.import_rule_type(import_rule_type_id) default(1),
priority int2 not null constraint df_bank_import_rule_priority default(32767),
row_creation_date timestamp not null constraint df_bank_import_rule_dt default(current_timestamp),
start_date date not null constraint df_bank_import_rule_start_date default('1900-01-01'),
end_date date not null constraint df_bank_import_rule_end_date default('2099-12-31')
);

/* import_rule fields relating to matching records */
create table bank.import_rule_fields_to_match
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_fields_to_match unique,
type varchar(50) null,
other_party_bank_account_number varchar(56) null,
details varchar(50) null,
particulars varchar(50) null,
code varchar(50) null,
reference varchar(50) null,
ofx_name varchar(50) NULL,
ofx_memo varchar(255) NULL,
wildcard_field varchar(50) null
);

create table bank.import_rule_gl_rules_assets
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_assets unique,
bank_account_id int4 null references bank.account(bank_account_id),
cash_account_id int4 null references books.account(account_id),
assets_account_id int4 not null references books.account(account_id)
);

create table bank.import_rule_gl_rules_liability
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_liability unique,
bank_account_id int4 null references bank.account(bank_account_id),
cash_account_id int4 null references books.account(account_id),
liability_account_id int4 not null references books.account(account_id)
);

create table bank.import_rule_gl_rules_equity
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_equity unique,
bank_account_id int4 null references bank.account(bank_account_id),
cash_account_id int4 null references books.account(account_id),
equity_account_id int4 not null references books.account(account_id)
);

create table bank.import_rule_gl_rules_income
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_income unique,
bank_account_id int4 null references bank.account(bank_account_id),
cash_account_id int4 null references books.account(account_id),
income_account_id int4 not null references books.account(account_id)
);

create table bank.import_rule_gl_rules_expense
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_expense unique,
bank_account_id int4 null references bank.account(bank_account_id),
cash_account_id int4 null references books.account(account_id),
expense_account_id int4 not null references books.account(account_id)
);

create table bank.import_rule_gl_rules_loan_repayment
(
import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_loan_repayment unique,
bank_account_id int4 null references bank.account(bank_account_id),
cash_account_id int4 not null references books.account(account_id),
bank_account_interest_payable_account_id int4 null references books.account(account_id),
bank_account_loan_principal_account_id int4 not null references books.account(account_id)
);

create table bank.transaction
(
transaction_id bigint generated by default as identity primary key,
bank_account_friendly_name varchar(256) not null,
bank_account_number varchar(56) null,
bank_account_id int4 not null references bank.account(bank_account_id),
--account_id int4 null references books.account(account_id),
--account_id_2 int4 null references books.account(account_id),
--other_party_account_id int4 null references books.account(account_id),
--other_party_account_id_2 int4 null references books.account(account_id),
--import_rule_id int4 null, -- optional. the rule applied to this GL entry
row_creation_date timestamp not null constraint df_bank_transaction_dt default(current_timestamp),
import_identifier int4 not null,
import_datetime timestamp not null constraint df_bank_transaction_import_datetime default(current_timestamp),
--is_imported_to_gl boolean not null constraint df_bank_transaction_is_imported_to_gl default (false),
imported_to_gl_datetime timestamp null,
transaction_date date not null,
processed_date date null,
amount numeric(16,2)  not null,
--amount_2 numeric(16,2)  not null, -- used if account_id_2 is used, for splits
balance numeric(16,2) null,
other_party_bank_account_number varchar(56) null,
type varchar(50) null, 
details varchar(50) null, 
particulars varchar(50) null, 
code varchar(50) null, 
reference varchar(50) NULL,
ofx_name varchar(50) NULL,
ofx_memo varchar(255) null,
matched_import_rule_id int4 null references bank.import_rule(import_rule_id)
);



create table load.anz_excel
(
line_id int8 generated by default as identity primary key,
bank_account_number varchar(50) NULL,
bank_account_friendly_name varchar(50) NULL,
"Transaction Date" varchar(50) null,
"Processed Date" varchar(50) null,
"Type" varchar(50) null,
"Details" varchar(50) null,
"Particulars" varchar(50) null,
"Code" varchar(50) null,
"Reference" varchar(50) null,
"Amount" varchar(50) null,
"Balance" varchar(50) null,
"To/From Account Number" varchar(50) null,
"Conversion Charge" varchar(50) null,
"Foreign Currency Amount" varchar(100) null
);

create table load.anz_mortgage_excel
(
line_id int8 generated by default as identity primary key,
bank_account_number varchar(50) NULL,
bank_account_friendly_name varchar(50) NULL,
"Date" varchar(50) null,
"Details" varchar(50) null,
"Amount" varchar(50) null,
"Balance" varchar(50) null
);

create table load.ofx
(
line_id int8 generated by default as identity primary key,
row_creation_date timestamp not null constraint df_load_ofx_dt default(current_timestamp),
bank_account_id int4 not null,
dtserver date null,
tranuid int4 null,
bankid varchar(50) null,
branchid varchar(50) null,
acctid varchar(50) null,
accttype varchar(50) null,
trntype varchar(50) null,
dtposted date null,
trnamt numeric(16,2) null,
fitid varchar(50) null,
name varchar(50) null,
memo varchar(255) NULL
);



create table books.general_ledger
(
gl_id bigint generated by default as identity primary key,
gl_type_id smallint not null constraint df_gl_type_id default(1), -- Journal Entry
gl_date date not null,
gl_grouping_id bigint not null, -- group related rows together
row_creation_date timestamp not null constraint df_gl_dt default(current_timestamp),
account_id int null references books.account(account_id),
debit_amount numeric(16,2) not null constraint df_gl_dr default(0),
credit_amount numeric(16,2) not null constraint df_gl_cr default(0),
memo varchar(256) null,
bank_account_id int4 null references bank.account(bank_account_id), -- optional. bank account id, matches bank.account id.
bank_transaction_id int8 null references bank.transaction(transaction_id),  -- optional. bank transaction id from input table
matched_import_rule_id int4 null references bank.import_rule(import_rule_id) -- optional. the import rule applied to this tx
);

-- drop table fact.account_summary_by_month
create table fact.account_summary_by_month
(
account_id int not null,
year int not null,
month_number int not null,
month_end_date date not null,
debit_amount numeric(16,2),
credit_amount numeric(16,2),
debit_amount_running_total numeric(16,2),
credit_amount_running_total numeric(16,2),
balance numeric(16,2)
);


create table dimension.dates
(
datekey date not null unique,
year int not null,
month_number int not null,
month_text varchar(10) not null,
month_year_text varchar(12) not null,
month_year_date date not null
);

insert into dimension.dates(datekey, year, month_number, month_text, month_year_text, month_year_date)
SELECT d.date, 
date_part('year', d.date), 
date_part('month', d.date), 
to_char(d.date, 'Mon'), 
to_char(d.date, 'Mon YYYY'),
(date_trunc('MONTH', d.date) + INTERVAL '1 MONTH - 1 day')::date
FROM GENERATE_SERIES('2016-01-01', '2050-01-01', '1 day'::INTERVAL) d
;

