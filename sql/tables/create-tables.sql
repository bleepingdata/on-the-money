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
external_friendly_name varchar(256) null,
external_unique_identifier varchar(56) null
);
create index uq_books_external_unique_identifier on books.account(external_unique_identifier) where external_unique_identifier is not null;

insert into books.account (account_id, account_type_id, account_code, description, open_date, close_date)
	values (0, 0, '0', 'unknown account', '1900-01-01', '2099-12-31');

create table load.anz_export_file
(
file_id bigint generated by default as identity primary key,
bankaccountnumber varchar(50) NULL,
bankaccountdescription varchar(50) NULL,
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

create table books.load_import_file_excel_anzmortgage
(
load_import_file_excel_anzmortgage_id bigint generated by default as identity primary key,
bankaccountnumber varchar(50) NULL,
bankaccountdescription varchar(50) NULL,
"Date" varchar(50) null,
"Details" varchar(50) null,
"Amount" varchar(50) null,
"Balance" varchar(50) null
);
/*

create table books.transaction
(
transactionid bigint generated by default as identity primary key,
sourceaccountid int NOT NULL REFERENCES books.account(accountid),
banktransactiondate date not null,
bankprocesseddate date null,
transactionxml xml not null,
amount numeric(16,2)  not null,
importdatetime timestamp not null constraint df_books_transaction_importdatetime default(current_timestamp),
importseq int not null,
type varchar(50) null, 
details varchar(50) null,  
particulars varchar(50) null, 
code varchar(50) null, 
reference varchar(50) null,
isprocessed boolean not null constraint df_books_transaction default (false),
processeddatetime timestamp null,
rowcreationdate timestamp not null constraint df_books_transaction_dt default(current_timestamp)
);
*/

/*
create table books.transactionline
(
transactionlineid bigint generated by default as identity primary key,
transactionid bigint not null references books.transaction(transactionid),
accountid int null references books.account(accountid),
depositamount numeric(16,2)  null,
withdrawalamount numeric(16,2)  null,
rowcreationdate timestamp not null constraint df_books_transactionline_dt default(current_timestamp)
);

*/

create table books.bank_transaction
(
bank_transaction_id bigint generated by default as identity primary key,
bank_account_friendly_name varchar(256) not null,
bank_account_number varchar(56) not null,
bank_transaction_date date not null,
bank_processed_date date null,
transaction_xml xml not null,
amount numeric(16,2)  not null,
import_datetime timestamp not null constraint df_stage_bank_transaction_import_datetime default(current_timestamp),
import_seq int not null,
type varchar(50) null, 
details varchar(50) null, 
particulars varchar(50) null, 
code varchar(50) null, 
reference varchar(50) null,
is_processed boolean not null constraint df_stage_bank_transaction default (false),
processed_datetime timestamp null,
row_creation_date timestamp not null constraint df_stage_bank_transaction_dt default(current_timestamp)
);

create table books.general_ledger
(
gl_id bigint generated by default as identity primary key,
gl_type_id smallint not null constraint df_gl_type_id default(1), -- Journal Entry
gl_date date not null,
gl_grouping_id bigint not null, -- group related rows together
row_creation_date timestamp not null constraint df_gl_dt default(current_timestamp),
account_id int null references books.account(account_id),
debit_amount numeric(16,2)  null,
credit_amount numeric(16,2) null,
memo varchar(256) null,
source_identifier bigint null  -- e.g. optional. bank transaction id from input table
);


create table books.transactionimportrules
(
transactionimportrulesid int generated by default as identity primary key,
fromaccountid int not null references books.account(accountid),
toaccountid int not null references books.account(accountid),
rowcreationdate timestamp not null constraint df_books_transactionimportrules_dt default(current_timestamp),
appliesfromdate date not null constraint df_books_transactionimportrules_appliesfromdate default('1900-01-01'),
appliesuntildate date not null constraint df_books_transactionimportrules_appliesuntildate default('2099-12-31'),
type varchar(50) null,
details varchar(50) null,
particulars varchar(50) null,
code varchar(50) null,
reference varchar(50) null
);
 

create table fact.account_summary_by_month
(
accountid int not null,
year int not null,
month int not null,
month_as_date date not null,
deposit_amount numeric(16,2),
withdrawal_amount numeric(16,2),
deposit_amount_running_total numeric(16,2),
withdrawal_amount_running_total numeric(16,2),
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
