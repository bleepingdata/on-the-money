-- Assets
INSERT into books.account(account_type_id, account_code, description, open_date, close_date) 
	VALUES (1 /* Assets */, '10001', 'Cash', '2017-01-01', '2099-12-31');
INSERT into books.account(account_type_id, account_code, description, open_date, close_date) 
	VALUES (1 /* Assets */, '19999', 'Other Assets', '2017-01-01', '2099-12-31');

-- Liabilities
INSERT into books.account(account_type_id, account_code, description, open_date, close_date) 
	VALUES (1 /* Liabilities */, '29999', 'Other Liabilities', '2017-01-01', '2099-12-31');

-- Equity
INSERT into books.account(account_type_id, account_code, description, open_date, close_date)
	 VALUES (3 /* Equity */, '30001', 'Opening Balance Equity', '2017-01-01', '2099-12-31');
INSERT into books.account(account_type_id, account_code, description, open_date, close_date)
	 VALUES (3 /* Equity */, '30002', 'Bank Transfers', '2017-01-01', '2099-12-31');

-- Income Accounts
INSERT into books.account(account_type_id, account_code, description, open_date, close_date)
	 VALUES (4 /* Income */, '49999', 'Other Income', '2017-01-01', '2099-12-31');

-- Expense Accounts
INSERT into books.account(account_type_id, account_code, description, open_date, close_date)
	 VALUES (5 /* Expense */, '59999', 'Other Expense', '2017-01-01', '2099-12-31');
INSERT into books.account(account_type_id, account_code, description, open_date, close_date)
	 VALUES (5 /* Expense */, '59998', 'Bank Charges', '2017-01-01', '2099-12-31');

