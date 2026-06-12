DROP FUNCTION IF EXISTS books.get_accounts;

-- ============================================================
-- Function : books.get_accounts(varchar)
-- ============================================================
-- Purpose  : Returns a list of accounts optionally filtered by account type
--            (e.g. 'Asset', 'Liability'), ordered by account code.
--
-- Parameters
--   s_account_type  (varchar) : Account type to filter by; pass NULL to
--                               return all accounts.
--
-- Returns  : TABLE (account_id int, account_code char(10), description varchar(50))
--
-- Usage
--   SELECT * FROM books.get_accounts('Asset');
--   SELECT * FROM books.get_accounts(NULL);
--
-- Dependencies
--   Tables    : books.account, books.account_type
-- ============================================================
CREATE OR REPLACE FUNCTION books.get_accounts(s_account_type varchar(50) DEFAULT NULL)
RETURNS TABLE (
    account_id int,
    account_code char(10),
    description varchar(50)
)
AS $$
BEGIN
    RETURN QUERY
    SELECT a.account_id,
        a.account_code,
        a.description
    FROM books.account a
        INNER JOIN books.account_type at ON a.account_type_id = at.account_type_id
    WHERE (s_account_type IS NULL OR at.account_type = s_account_type)
    ORDER BY a.account_code;
END;
$$ LANGUAGE plpgsql;