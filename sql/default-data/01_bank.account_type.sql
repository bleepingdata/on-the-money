insert into bank.account_type (bank_account_type_id, bank_account_type, description) values
    (0, 'unknown', 'Unknown bank account type'),
    (1, 'cash', 'Cash account, e.g. current account'),
    (2, 'debt', 'Debt account, e.g. mortgage'),
    (3, 'credit', 'Credit account, e.g. credit card')
on conflict (bank_account_type_id) do nothing;
