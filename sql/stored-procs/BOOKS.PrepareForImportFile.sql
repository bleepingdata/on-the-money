USE OnTheMoney
GO
DROP PROC BOOKS.PrepareForImportFile
GO
CREATE PROC BOOKS.PrepareForImportFile @BankAccountNumber NVARCHAR(56) = NULL, @BankAccountDescription NVARCHAR(50) = NULL
AS
BEGIN
-- Process a bank file from ANZ. The file contents must already exist in BOOKS.LoadImportFile table. Parameters determine which account the
-- transactions will be recorded against

	SET NOCOUNT ON;

	IF @BankAccountNumber IS NULL AND @BankAccountDescription IS NULL
	BEGIN
		RAISERROR('All parameters for proc are null or missing', 15,1);
	END

	-- get the bank account id
	DECLARE @BankAccountId INT = (SELECT AccountId FROM BOOKS.Account 
									WHERE 
										BankAccountNumber = ISNULL(@BankAccountNumber, BankAccountNumber) 
										AND Description = ISNULL(@BankAccountDescription, Description)
										AND (@BankAccountNumber IS NOT NULL OR @BankAccountDescription IS NOT NULL));
	IF @BankAccountId IS NULL
	BEGIN
		RAISERROR('Unable to find BOOKS.Account entry for bank account %s, description %s', 15,1, @BankAccountNumber, @BankAccountDescription);
	END

	-- truncate the table that will hold the imported data
	TRUNCATE TABLE BOOKS.LoadImportFile;

	RETURN;

END