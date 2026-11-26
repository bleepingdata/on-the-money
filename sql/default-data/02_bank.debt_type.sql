insert into bank.debt_type (debt_type_id, debt_type, description) values
    (0, 'unknown', 'Unknown debt type'),
    (1, 'fixed-rate-mortgage', 'Fixed Rate Mortgage'),
    (2, 'interest-only', 'Interest Only')
on conflict (debt_type_id) do nothing;
