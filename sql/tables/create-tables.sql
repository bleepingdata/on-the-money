create table books.accounttype
(
accounttypeid smallint generated by default as identity primary key,
description varchar(50) not null constraint uq_books_accounttype_description unique
);

insert into books.accounttype(accounttypeid, description) values (0, 'unknown account type');
insert into books.accounttype(accounttypeid, description) values (1, 'assets');
insert into books.accounttype(accounttypeid, description) values (2, 'liabilities');
insert into books.accounttype(accounttypeid, description) values (3, 'equity');
insert into books.accounttype(accounttypeid, description) values (4, 'income');
insert into books.accounttype(accounttypeid, description) values (5, 'expense');

create table books.account
(
accountid int generated by default as identity primary key,
accounttypeid smallint not null references books.accounttype(accounttypeid),
accountcode char(10) not null constraint uq_books_account_accountcode unique,
description varchar(50) not null constraint uq_books_account_description unique,
bankaccountnumber varchar(56) null,
openingbalance numeric(16,2) not null,
openingbalancedate date not null,
balance numeric(16,2) not null constraint df_books_account_balance default(0)
);
create index uq_books_account_bankaccountnumber on books.account(bankaccountnumber) where bankaccountnumber is not null;

insert into books.account (accountid, accounttypeid, accountcode, description, openingbalance, openingbalancedate, balance)
	values (0, 0, '0', 'unknown account', 0, '1900-01-01', 0);


create table books.loadimportfile
(
LoadImportFileId bigint generated by default as identity primary key,
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
"Foreign Currency Amount" varchar(50) null
);

create table books.loadimportfile_excel_anzmortgage
(
id bigint generated by default as identity primary key,
date varchar(50) null,
details varchar(50) null,
amount varchar(50) null,
balance varchar(50) null
);

create table books.transaction
(
transactionid bigint generated by default as identity primary key,
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

create table books.transactionline
(
transactionlineid bigint generated by default as identity primary key,
transactionid bigint not null references books.transaction(transactionid),
accountid int null references books.account(accountid),
depositamount numeric(16,2)  null,
withdrawalamount numeric(16,2)  null,
rowcreationdate timestamp not null constraint df_books_transactionline_dt default(current_timestamp)
);


create table books.transactionstaging
(
transactionstagingid bigint generated by default as identity primary key,
banktransactiondate date not null,
bankprocesseddate date null,
transactionxml xml not null,
amount numeric(16,2)  not null,
importdatetime timestamp not null constraint df_books_transactionstaging_importdatetime default(current_timestamp),
importseq int not null,
type varchar(50) null, 
details varchar(50) null, 
particulars varchar(50) null, 
code varchar(50) null, 
reference varchar(50) null,
isprocessed boolean not null constraint df_books_transactionstaging default (false),
processeddatetime timestamp null,
rowcreationdate timestamp not null constraint df_books_transactionstaging_dt default(current_timestamp)
);

create table books.transactionlinestaging
(
transactionlinestagingid bigint generated by default as identity primary key,
transactionstagingid bigint references books.transactionstaging(transactionstagingid),
accountid int null references books.account(accountid),
depositamount numeric(16,2)  null,
withdrawalamount numeric(16,2) null,
rowcreationdate timestamp not null constraint df_books_transactionlinestaging_dt default(current_timestamp)
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


