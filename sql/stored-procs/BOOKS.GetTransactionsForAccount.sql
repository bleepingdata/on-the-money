USE OnTheMoney
GO
DROP PROC BOOKS.GetTransactionsForAccount
GO
CREATE PROC BOOKS.GetTransactionsForAccount @AccountId INT
AS
BEGIN
/* 
 Get the balance for an account at a date, taking the opening balance into account
 */
	SET NOCOUNT ON;


	-- attempt 2 - the balance is effective based on Bank Processed Date but may include older transactions based on Bank Transaction Date
	select AccountId, BankTransactionDate, BankProcessedDate, Amount, 
		sum(Amount) over (partition by AccountId order by ISNULL(t.BankProcessedDate, '2100-01-01'), t.Transactionid) AS [Balance]
		from 
		(
			SELECT 0 AS [TransactionId], AccountId, OpeningBalanceDate AS [BankTransactionDate], OpeningBalanceDate AS [BankProcessedDate], OpeningBalance AS [Amount]
				FROM BOOKS.Account a
				WHERE a.AccountId=@AccountId
			UNION ALL
			select t.TransactionId, tl.AccountId, BankTransactionDate, BankProcessedDate, (DepositAmount - WithdrawalAmount) AS [Amount]
				from BOOKS.[Transaction] t 
					INNER JOIN BOOKS.[TransactionLine] tl ON t.TransactionId = tl.TransactionId
					INNER JOIN BOOKS.Account a ON tl.AccountId = a.AccountId
				WHERE tl.AccountId=@AccountId
					AND ISNULL(t.BankProcessedDate, '2100-01-01') >= a.OpeningBalanceDate
			) t
		order by AccountId ASC, ISNULL(t.BankProcessedDate, '2100-01-01') DESC, t.Transactionid DESC;

END
GO