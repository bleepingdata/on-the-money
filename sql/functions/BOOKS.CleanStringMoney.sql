CREATE OR replace FUNCTION BOOKS.CleanStringMoney(MoneyAsString VARCHAR(50))
RETURNS MONEY as $$
declare amount money;
BEGIN
DECLARE WorkingString VARCHAR(50);

SELECT RTRIM($1) into WorkingString;
--SET WorkingString = REPLACE(WorkingString, '$', '');
--SET WorkingString = REPLACE(WorkingString, ' ', '');

--SELECT CAST(WorkingString as MONEY) into amount;

return amount;
END;
$$ LANGUAGE plpgsql;



CREATE OR replace FUNCTION BOOKS.CleanStringMoney(MoneyAsString VARCHAR(50))
RETURNS MONEY as $$
declare amount money;
BEGIN
DECLARE WorkingString VARCHAR(50);
return amount;
END;
$$ LANGUAGE plpgsql;