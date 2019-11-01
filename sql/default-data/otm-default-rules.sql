-- Import Rules
-- Add common rules to all accounts. These can be overruled if a similar rule is created with a higher priority.

-- Expenses categorised by Type
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Eft-Pos', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Visa Purchase', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Atm Debit', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Payment', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Automatic Payment', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Direct Debit', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'Foreign Exchange', n_priority:=-32766::int2);
-- common OFX types
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'CREDIT', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'DEBIT', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'ATM', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'PAYMENT', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'DEP', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Other Expense', s_type := 'REPEATPMT', n_priority:=-32766::int2);

-- Bank Charges categorised by Type
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Bank Charges', s_type := 'Failed Payment', n_priority:=-32766::int2);
select bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account :='Bank Charges', s_type := 'Bank Fee', n_priority:=-32766::int2);


 