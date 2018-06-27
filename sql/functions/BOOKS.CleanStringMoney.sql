USE OnTheMoney
GO

CREATE FUNCTION BOOKS.CleanStringMoney(@MoneyAsString VARCHAR(50))
RETURNS MONEY
BEGIN
DECLARE @WorkingString VARCHAR(50);

SET @WorkingString = RTRIM(@MoneyAsString);
SET @WorkingString = REPLACE(@WorkingString, '$', '');
SET @WorkingString = REPLACE(@WorkingString, ' ', '');

RETURN TRY_CONVERT(MONEY, @WorkingString);
END
