USE OnTheMoney
GO

CREATE PROC BOOKS.ProcessImportRules @ReprocessAll BIT = 0
AS
BEGIN
	
	UPDATE to_transaction_lines
	SET AccountId = from_transaction_lines.ToAccountId -- SELECT *
	FROM BOOKS.TransactionLine to_transaction_lines
	INNER JOIN
	(
		SELECT tl.AccountId AS [FromAccountId], tl.Transactionid, tir.ToAccountID
		FROM BOOKS.TransactionLine tl
			INNER JOIN BOOKS.[Transaction] t ON tl.TransactionId = t.TransactionId
			INNER JOIN BOOKS.TransactionImportRules tir ON tl.AccountID = tir.FromAccountId 
					AND tir.AppliesFromDate <= t.BankTransactionDate 
					AND tir.AppliesUntilDate >= t.BankTransactionDate
		WHERE 
			(t.[Type] = tir.[Type] OR tir.[Type] IS NULL)
			AND (t.[Details] = tir.[Details] OR tir.[Details] IS NULL)
			AND (t.[Particulars] = tir.[Particulars] OR tir.[Particulars] IS NULL)
			AND (t.[Code] = tir.[Code] OR tir.[Code] IS NULL)
			AND (t.[Reference] = tir.[Reference] OR tir.[Reference] IS NULL)
		) from_transaction_lines
		ON from_transaction_lines.TransactionId = to_transaction_lines.TransactionId
			AND from_transaction_lines.FromAccountId <> to_transaction_lines.AccountId
		WHERE 
			(@ReprocessAll = 1 OR to_transaction_lines.AccountId = 0) -- process only AccountId 0 (unknown) unless @ReprocessAll is 1 (true)

END
GO
