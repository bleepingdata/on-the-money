DROP FUNCTION IF EXISTS books.cleanstringmoney;

-- ============================================================
-- Function : books.cleanstringmoney(varchar)
-- ============================================================
-- Purpose  : Stub function intended to strip currency symbols and whitespace
--            from a money string and cast it to money. The conversion logic
--            is commented out; the function always returns NULL.
--
-- Parameters
--   moneyasstring  (varchar) : The money value as a string (e.g. '$ 1,234.56').
--
-- Returns  : money — always NULL in the current implementation.
--
-- Usage
--   SELECT books.cleanstringmoney('$ 1,234.56');
--
-- Dependencies
--   Tables    : (none)
-- ============================================================
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