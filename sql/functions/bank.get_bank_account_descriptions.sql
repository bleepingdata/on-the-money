DROP FUNCTION IF EXISTS bank.get_bank_account_descriptions(boolean);

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