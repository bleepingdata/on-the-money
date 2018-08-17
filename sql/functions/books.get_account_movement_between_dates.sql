USE OnTheMoney
GO
CREATE OR replace function books.get_account_movement_between_dates @AccountId INT, @StartDate DATE, @EndDate DATE
AS
BEGIN
/* 
 Get the balance for an account at a date, taking the opening balance into account
 */
	SET NOCOUNT ON;

		DECLARE @DepositAmountTotal MONEY 
			= ISNULL(
						(SELECT SUM(DepositAmount) 
							FROM BOOKS.[Transaction] t
								INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
                                INNER JOIN BOOKS.Account a  ON tl.AccountId = a.AccountId
								WHERE ISNULL(t.BankProcessedDate, '2100-01-01') >= a.OpeningBalanceDate
                                    AND a.AccountId = @AccountId
									AND t.BankProcessedDate >= @StartDate
                                    AND t.BankProcessedDate <= @EndDate)
							,0);
		DECLARE @WithdrawalAmountTotal MONEY 
			= ISNULL(
						(SELECT SUM(WithdrawalAmount) 
							FROM BOOKS.[Transaction] t
								INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
								INNER JOIN BOOKS.Account a  ON tl.AccountId = a.AccountId
								WHERE ISNULL(t.BankProcessedDate, '2100-01-01') >= a.OpeningBalanceDate
                                    AND a.AccountId = @AccountId
                                    AND t.BankProcessedDate >= @StartDate
                                    AND t.BankProcessedDate <= @EndDate)
							,0);


SELECT @AccountId AS [AccountId], @StartDate as [StartDate], @EndDate as [EndDate],  (@DepositAmountTotal - @WithdrawalAmountTotal) AS [Movement]

END
GO