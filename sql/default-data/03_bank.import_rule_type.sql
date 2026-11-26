insert into bank.import_rule_type (import_rule_type_id, import_rule_type, description) values
    (0, 'unknown', 'Unknown Import Rule'),
    (1, 'asset-purchase', 'An asset purchase from the bank to an asset account with no transaction splits'),
    (2, 'loan-drawdown', 'A liability increase from the bank with no transaction splits'),
    (3, 'loan-interest', 'A liability increase from the bank for interest on a loan with no transaction splits'),
    (4, 'loan-repayment', 'A liability decrease from the bank where interest payable is paid down, and any remaining credits go against the loan principal'),
    (5, 'income', 'An income deposit to revenue accounts with no transaction splits'),
    (6, 'expense', 'An expense from the bank to an expense account with no transaction splits'),
    (7, 'interest-only-loan-repayment', 'A payment of interest incurred in an interest only loan payables account'),
    (8, 'bank-transfer-in', 'A bank transfer into a bank accounts'),
    (9, 'bank-transfer-out', 'A bank transfer out of a bank accounts')
on conflict (import_rule_type_id) do nothing;
