USE OnTheMoney
GO
DROP PROC BOOKS.CalculateBalance
GO
CREATE PROC BOOKS.CalculateBalance @AccountId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @AccountIds TABLE (AccountId INT NOT NULL);
	DECLARE @NextAccountId TABLE (AccountId INT NOT NULL);
	DECLARE @NextAccountIdInt INT;

	IF @AccountId IS NOT NULL
	BEGIN
		INSERT @AccountIds VALUES (@AccountId);
	END
	ELSE
	BEGIN
		INSERT @AccountIds
		SELECT AccountId FROM BOOKS.Account;
	END

	WHILE EXISTS (SELECT * FROM @AccountIds)
	BEGIN
		-- update balances for all accounts
		DELETE TOP(1) @AccountIds OUTPUT deleted.AccountId INTO @NextAccountId;
		
		SET @NextAccountIdInt = (SELECT AccountId FROM @NextAccountId);
		RAISERROR('Updating balance for AccountId %i', 1, 1, @NextAccountIdInt) WITH NOWAIT;
		
		DECLARE @DepositAmountTotal MONEY = ISNULL((SELECT SUM(DepositAmount) FROM BOOKS.TransactionLine tl INNER JOIN @NextAccountId next_ac on tl.AccountId = next_ac.AccountId),0);
		DECLARE @WithdrawalAmountTotal MONEY = ISNULL((SELECT SUM(WithdrawalAmount) FROM BOOKS.TransactionLine tl INNER JOIN @NextAccountId next_ac on tl.AccountId = next_ac.AccountId),0);

		UPDATE a SET a.Balance = OpeningBalance + (@DepositAmountTotal - @WithdrawalAmountTotal) 
			FROM BOOKS.Account a 
				INNER JOIN @NextAccountId next_ac ON a.AccountId = next_ac.AccountId;

		DELETE FROM @NextAccountId;
	END

END
GO