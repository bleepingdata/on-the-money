USE OnTheMoney
GO
DROP PROC BOOKS.CalculateBalance
GO
CREATE PROC BOOKS.CalculateBalance @AccountId INT = NULL
AS
BEGIN
/* 
 Get the balance for an account or accounts, taking the opening balance into account
 */
 	SET NOCOUNT ON;

	DECLARE @AccountIds TABLE (AccountId INT NOT NULL, OpeningBalanceDate DATE NOT NULL);
	DECLARE @NextAccountId TABLE (AccountId INT NOT NULL, OpeningBalanceDate DATE NOT NULL);
	DECLARE @NextAccountIdInt INT;

	IF @AccountId IS NOT NULL
	BEGIN
		-- update balance of a single account, based on @AccountId
		INSERT @AccountIds (AccountId, OpeningBalanceDate) SELECT AccountId, OpeningBalanceDate FROM BOOKS.Account WHERE AccountId = @AccountId;
	END
	ELSE
	BEGIN
		-- update balance of all accounts, based on BOOKS.Account
		INSERT @AccountIds (AccountId, OpeningBalanceDate)
		SELECT AccountId, OpeningBalanceDate FROM BOOKS.Account;
	END

	WHILE EXISTS (SELECT * FROM @AccountIds)
	BEGIN
		-- update balances for accounts
		DELETE TOP(1) @AccountIds OUTPUT deleted.AccountId, deleted.OpeningBalanceDate INTO @NextAccountId (AccountId, OpeningBalanceDate);
		
		SET @NextAccountIdInt = (SELECT AccountId FROM @NextAccountId);
		
		RAISERROR('Updating balance for AccountId %i', 1, 1, @NextAccountIdInt) WITH NOWAIT;
		
		DECLARE @DepositAmountTotal MONEY 
			= ISNULL(
						(SELECT SUM(DepositAmount) 
							FROM BOOKS.[Transaction] t
								INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
								INNER JOIN @NextAccountId next_ac on tl.AccountId = next_ac.AccountId
								WHERE t.BankProcessedDate >= next_ac.OpeningBalanceDate)
							,0);
		DECLARE @WithdrawalAmountTotal MONEY 
			= ISNULL(
						(SELECT SUM(WithdrawalAmount) 
							FROM BOOKS.[Transaction] t
								INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
								INNER JOIN @NextAccountId next_ac on tl.AccountId = next_ac.AccountId
								WHERE ISNULL(t.BankProcessedDate, '2100-01-01') >= next_ac.OpeningBalanceDate)
							,0);

		UPDATE a SET a.Balance = OpeningBalance + (@DepositAmountTotal - @WithdrawalAmountTotal) 
			FROM BOOKS.Account a 
				INNER JOIN @NextAccountId next_ac ON a.AccountId = next_ac.AccountId;

		DELETE FROM @NextAccountId;
	END

END
GO