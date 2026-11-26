DROP FUNCTION IF EXISTS bank.get_bank_account_balance_summary(boolean);

-- ============================================================
-- Function : bank.get_bank_account_balance_summary(boolean)
-- ============================================================
-- Purpose  : Returns a summary of bank account balances grouped by
--            bank account type (account count and total balance).
--
-- Parameters
--   b_include_closed  (boolean) : When TRUE, includes accounts whose
--                                 close_date is in the past. Defaults to FALSE.
--
-- Returns  : TABLE
--              bank_account_type  varchar : Account type, e.g. 'cash', 'debt', 'credit'.
--              account_count      bigint  : Number of bank accounts of that type.
--              total_balance      numeric : Sum of the current balances for that type.
--
-- Usage
--   SELECT * FROM bank.get_bank_account_balance_summary();
--   SELECT * FROM bank.get_bank_account_balance_summary(TRUE);
--
-- Dependencies
--   Functions : bank.get_bank_accounts_with_balances
-- ============================================================
CREATE OR REPLACE FUNCTION bank.get_bank_account_balance_summary(b_include_closed boolean DEFAULT FALSE)
RETURNS TABLE (
    bank_account_type varchar,
    account_count bigint,
    total_balance numeric
) AS $$
BEGIN
    -- Validate required parameters
    IF b_include_closed IS NULL THEN
        RAISE EXCEPTION 'b_include_closed must not be NULL'
            USING HINT = 'Pass TRUE or FALSE, or omit the parameter to use the default';
    END IF;

    RETURN QUERY
    SELECT
        f.bank_account_type,
        COUNT(*)::bigint AS account_count,
        COALESCE(SUM(f.current_balance), 0)::numeric AS total_balance
    FROM bank.get_bank_accounts_with_balances(b_include_closed) AS f
    GROUP BY f.bank_account_type
    ORDER BY f.bank_account_type;
END;
$$ LANGUAGE plpgsql;
