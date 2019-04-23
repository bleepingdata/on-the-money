drop view fact.account;
drop view fact.account_balance;
drop view fact.account_movement;
drop view fact.transactions;
drop view fact.uncategorised_transactions;

drop table books.general_ledger;
DROP TABLE BOOKS.TransactionLine;
DROP TABLE BOOKS.Transaction;
drop table BOOKS.transactionlinestaging;
DROP TABLE BOOKS.transactionstaging;
DROP TABLE BOOKS.LoadImportFile;
DROP TABLE BOOKS.loadimportfile_excel_anzmortgage;
drop table BOOKS.TransactionImportRules;
DROP TABLE BOOKS.Account;
DROP TABLE BOOKS.Account_Type;

drop table fact.account_summary_by_month;


DROP SCHEMA BOOKS;
drop schema fact;
drop schema stage;
drop schema dimension;