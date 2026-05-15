DROP FUNCTION IF EXISTS bank.get_bank_account_descriptions(boolean);

-- ============================================================
-- Function : bank.get_bank_account_descriptions(boolean)
-- ============================================================
-- Purpose  : Returns the descriptions of all bank accounts,
--            optionally including accounts that have been closed.
--
-- Parameters
--   b_include_closed  (boolean) : When TRUE, includes accounts whose
--                                 close_date is in the past. Defaults to FALSE.
--
-- Returns  : TABLE
--              description  varchar : The account description.
--
-- Usage
--   SELECT * FROM bank.get_bank_account_descriptions();
--   SELECT * FROM bank.get_bank_account_descriptions(TRUE);
--
-- Dependencies
--   Tables    : bank.account
-- ============================================================
CREATE OR REPLACE FUNCTION bank.get_bank_account_descriptions(b_include_closed boolean DEFAULT FALSE)
RETURNS TABLE (description varchar) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.description
    FROM 
        bank.account a
    WHERE 
        (b_include_closed IS TRUE OR a.close_date >= current_date)
    ORDER BY 
        a.description;
END;
$$ LANGUAGE plpgsql;