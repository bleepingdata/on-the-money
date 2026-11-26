-- Common import rules applied to all accounts. These can be overruled by a similar rule with a higher priority.
-- Import rules have no natural key to upsert on, so the seed only runs when no import rules exist.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM bank.import_rule) THEN

        -- Expenses categorised by Type
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Eft-Pos', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Visa Purchase', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Atm Debit', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Payment', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Automatic Payment', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Direct Debit', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'Foreign Exchange', n_priority := -32766::int2);

        -- Common OFX types
        PERFORM bank.insert_import_rule_gl_rules_income (s_cash_account := 'Cash', s_income_account := 'Other Income', s_type := 'CREDIT', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'DEBIT', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'ATM', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'PAYMENT', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'DEP', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Other Expense', s_type := 'REPEATPMT', n_priority := -32766::int2);

        -- Bank charges categorised by Type
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Bank Charges', s_type := 'Failed Payment', n_priority := -32766::int2);
        PERFORM bank.insert_import_rule_gl_rules_expense (s_cash_account := 'Cash', s_expense_account := 'Bank Charges', s_type := 'Bank Fee', n_priority := -32766::int2);

    END IF;
END;
$$;
