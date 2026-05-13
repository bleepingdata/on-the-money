DROP FUNCTION IF EXISTS books.get_accounts;

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