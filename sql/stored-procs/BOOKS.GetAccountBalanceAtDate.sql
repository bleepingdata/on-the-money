USE OnTheMoney
GO
DROP PROC BOOKS.GetAccountBalanceAtDate
GO
CREATE PROC BOOKS.GetAccountBalanceAtDate @AccountId INT, @Date DATE
AS
BEGIN
/* 
 Get the balance for an account at a date, taking the opening balance into account
 */
	SET NOCOUNT ON;

        DECLARE @OpeningBalance MONEY = (SELECT OpeningBalance FROM BOOKS.Account WHERE AccountId = @AccountId);

		DECLARE @DepositAmountTotal MONEY 
			= ISNULL(
						(SELECT SUM(DepositAmount) 
							FROM BOOKS.[Transaction] t
								INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
                                INNER JOIN BOOKS.Account a  ON tl.AccountId = a.AccountId
								WHERE ISNULL(t.BankProcessedDate, '2100-01-01') >= a.OpeningBalanceDate
                                    AND a.AccountId = @AccountId
                                    AND t.BankProcessedDate <= @Date)
							,0);
		DECLARE @WithdrawalAmountTotal MONEY 
			= ISNULL(
						(SELECT SUM(WithdrawalAmount) 
							FROM BOOKS.[Transaction] t
								INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
								INNER JOIN BOOKS.Account a  ON tl.AccountId = a.AccountId
								WHERE ISNULL(t.BankProcessedDate, '2100-01-01') >= a.OpeningBalanceDate
                                    AND a.AccountId = @AccountId
                                    AND t.BankProcessedDate <= @Date)
							,0);


SELECT @AccountId AS [AccountId], @Date as [BalanceDate], (@OpeningBalance) + (@DepositAmountTotal - @WithdrawalAmountTotal) AS [Balance]

END
GO