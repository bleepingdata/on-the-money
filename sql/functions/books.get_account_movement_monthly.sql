CREATE OR replace function get_account_movement_monthly
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @CurrentAccountId INT = (SELECT MIN(AccountId) FROM BOOKS.Account);
	DECLARE @MonthlyAccountMovement TABLE (AccountId INT, StartDate DATE, EndDate DATE, Movement MONEY);

	WHILE EXISTS (SELECT * FROM BOOKS.Account WHERE AccountId = @CurrentAccountId)
	BEGIN

		DECLARE @CurrentMonth DATE = '2017-01-01';
		DECLARE @EOCurrentMonth DATE;

		WHILE @CurrentMonth < GETDATE()
		BEGIN
	
			SET @EOCurrentMonth = EOMONTH(@CurrentMonth);

			INSERT @MonthlyAccountMovement EXEC BOOKS.GetAccountMovementBetweenDates @AccountId=@CurrentAccountId, @StartDate=@CurrentMonth, @EndDate=@EOCurrentMonth

			SET @CurrentMonth = DATEADD(MONTH, 1, @CurrentMonth);
		END

		SET @CurrentAccountId = (SELECT MIN(AccountId) FROM BOOKS.Account WHERE AccountId > @CurrentAccountId);

	END

	SELECT a.Description, a.AccountTypeId, at.Description AS [AccountType], a.AccountCode, FORMAT(mam.EndDate, 'MMM yyyy') AS [DateDescription], mam.StartDate, mam.EndDate, mam.Movement 
		FROM @MonthlyAccountMovement mam
		INNER JOIN BOOKS.Account a ON mam.AccountId = a.AccountId
		INNER JOIN BOOKS.Accounttype at ON a.AccountTypeId = at.AccountTypeId
		ORDER BY a.AccountCode ASC, mam.EndDate ASC;

END
GO