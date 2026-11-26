insert into books.account_type (account_type_id, account_type, description) values
    (0, 'unknown', 'unknown'),
    (1, 'asset', 'Assests we own'),
    (2, 'liability', 'Liabilities we owe'),
    (3, 'equity', 'Equity'),
    (4, 'revenue', 'Revenue we generate, e.g. wages'),
    (5, 'expense', 'Expenses we have paid, e.g bills')
on conflict (account_type_id) do nothing;
