DROP FUNCTION IF EXISTS books.cleanstringmoney;
 
CREATE OR REPLACE FUNCTION books.cleanstringmoney(moneyasstring varchar(50))
RETURNS money
AS $$
DECLARE
    amount money;
    workingstring varchar(50);
BEGIN
    SELECT rtrim($1) INTO workingstring;
    -- set workingstring = replace(workingstring, '$', '');
    -- set workingstring = replace(workingstring, ' ', '');

    -- select cast(workingstring as money) into amount;

    RETURN amount;
END;
$$ LANGUAGE plpgsql;