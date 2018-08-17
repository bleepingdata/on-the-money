CREATE OR replace FUNCTION books.get_account_balance_monthly
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @CurrentAccountId INT = (SELECT MIN(AccountId) FROM BOOKS.Account);
	DECLARE @MonthlyAccountBalance TABLE (AccountId INT, BalanceDate DATE, Balance MONEY);

	WHILE EXISTS (SELECT * FROM BOOKS.Account WHERE AccountId = @CurrentAccountId)
	BEGIN

		DECLARE @CurrentMonth DATE = '2017-01-01';
		DECLARE @EOCurrentMonth DATE;

		WHILE @CurrentMonth < GETDATE()
		BEGIN
	
			SET @EOCurrentMonth = EOMONTH(@CurrentMonth);

			INSERT @MonthlyAccountBalance EXEC BOOKS.GetAccountBalanceAtDate @AccountId=@CurrentAccountId, @Date=@EOCurrentMonth

			SET @CurrentMonth = DATEADD(MONTH, 1, @CurrentMonth);
		END

		SET @CurrentAccountId = (SELECT MIN(AccountId) FROM BOOKS.Account WHERE AccountId > @CurrentAccountId);

	END

	SELECT a.Description, a.AccountTypeId, at.Description AS [AccountType], a.AccountCode, FORMAT(mab.BalanceDate, 'MMM yyyy') AS [BalanceDateDescription], mab.BalanceDate, mab.Balance FROM @MonthlyAccountBalance mab
		INNER JOIN BOOKS.Account a ON mab.AccountId = a.AccountId
		INNER JOIN BOOKS.Accounttype at ON a.AccountTypeId = at.AccountTypeId
		ORDER BY a.AccountCode ASC, mab.BalanceDate ASC;

END
GO