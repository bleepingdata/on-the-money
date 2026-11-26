DROP FUNCTION IF EXISTS bank.get_bank_accounts_with_balances(boolean);

-- ============================================================
-- Function : bank.get_bank_accounts_with_balances(boolean)
-- ============================================================
-- Purpose  : Returns each bank account with its current balance
--            (total debits minus total credits of the general ledger
--            entries linked to that bank account), plus activity details.
--
-- Parameters
--   b_include_closed  (boolean) : When TRUE, includes accounts whose
--                                 close_date is in the past. Defaults to FALSE.
--
-- Returns  : TABLE
--              bank_account_id        int     : Bank account primary key.
--              description            varchar : Bank account description.
--              bank_account_type      varchar : Account type, e.g. 'cash', 'debt', 'credit'.
--              open_date              date    : Date the account was opened.
--              close_date             date    : Date the account closes/closed.
--              current_balance        numeric : Debits minus credits, 0 when there are no entries.
--              last_transaction_date  date    : Latest GL date for the account, NULL when none.
--              transaction_count      bigint  : Number of GL entries for the account.
--
-- Usage
--   SELECT * FROM bank.get_bank_accounts_with_balances();
--   SELECT * FROM bank.get_bank_accounts_with_balances(TRUE);
--
-- Dependencies
--   Tables    : bank.account, bank.account_type, books.general_ledger
-- ============================================================
CREATE OR REPLACE FUNCTION bank.get_bank_accounts_with_balances(b_include_closed boolean DEFAULT FALSE)
RETURNS TABLE (
    bank_account_id int,
    description varchar,
    bank_account_type varchar,
    open_date date,
    close_date date,
    current_balance numeric,
    last_transaction_date date,
    transaction_count bigint
) AS $$
BEGIN
    -- Validate required parameters
    IF b_include_closed IS NULL THEN
        RAISE EXCEPTION 'b_include_closed must not be NULL'
            USING HINT = 'Pass TRUE or FALSE, or omit the parameter to use the default';
    END IF;

    RETURN QUERY
    -- Aggregate the ledger once per bank account rather than per joined row
    WITH gl_totals AS (
        SELECT
            gl.bank_account_id,
            SUM(gl.debit_amount - gl.credit_amount) AS balance,
            MAX(gl.gl_date) AS last_gl_date,
            COUNT(*) AS gl_count
        FROM books.general_ledger AS gl
        WHERE gl.bank_account_id IS NOT NULL
        GROUP BY gl.bank_account_id
    )
    SELECT
        a.bank_account_id,
        a.description::varchar,
        t.bank_account_type::varchar,
        a.open_date,
        a.close_date,
        COALESCE(g.balance, 0)::numeric AS current_balance,
        g.last_gl_date AS last_transaction_date,
        COALESCE(g.gl_count, 0)::bigint AS transaction_count
    FROM bank.account AS a
        INNER JOIN bank.account_type AS t ON a.bank_account_type_id = t.bank_account_type_id
        LEFT JOIN gl_totals AS g ON a.bank_account_id = g.bank_account_id
    WHERE b_include_closed IS TRUE OR a.close_date >= current_date
    ORDER BY a.description;
END;
$$ LANGUAGE plpgsql;
