-- Account 0 has an explicit id so it can be targeted by primary key.
-- Other rows use the identity sequence and are matched on their unique account_code.
insert into books.account (account_id, account_type_id, account_code, description, open_date, close_date, bank_account_id) values
    (0, 0, '0', 'unknown account', '1900-01-01', '2099-12-31', null)
on conflict (account_id) do nothing;

insert into books.account (account_type_id, account_code, description, open_date, close_date, bank_account_id) values
    (0, '00001', 'uncategorised debit', '1900-01-01', '2099-12-31', null),
    (0, '00002', 'uncategorised credit', '1900-01-01', '2099-12-31', null)
on conflict (account_code) do nothing;

insert into books.account (account_type_id, account_code, description, open_date, close_date, bank_account_id) values
    (1, '10001', 'Cash', '2017-01-01', '2099-12-31', null),
    (1, '19999', 'Other Assets', '2017-01-01', '2099-12-31', null),
    (2, '29999', 'Other Liabilities', '2017-01-01', '2099-12-31', null),
    (3, '30001', 'Opening Balance Equity', '2017-01-01', '2099-12-31', null),
    (3, '30002', 'Bank Transfers', '2017-01-01', '2099-12-31', null),
    (3, '30003', 'Revaluation Surplus', '2017-01-01', '2099-12-31', null),
    (4, '49999', 'Other Income', '2017-01-01', '2099-12-31', null),
    (5, '59999', 'Other Expense', '2017-01-01', '2099-12-31', null),
    (5, '59998', 'Bank Charges', '2017-01-01', '2099-12-31', null)
on conflict (account_code) do nothing;
