USE OnTheMoney
GO
DROP PROC BOOKS.ProcessImportFile
GO
CREATE PROC BOOKS.ProcessImportFile @BankAccountId INT
AS
BEGIN

DECLARE @ImportUniqueIdentifier UNIQUEIDENTIFIER = NEWID();

INSERT BOOKS.[Transaction] (BankTransactionDate, BankProcessedDate, TransactionXML, Amount, ImportUniqueIdentifier)
SELECT 
	TRY_CONVERT(DATE, [Transaction Date]) AS [BankTransactionDate], TRY_CONVERT(DATE, [Processed Date]) AS [BankProcessedDate],
		(SELECT [LoadImportFileId]
				  ,[Transaction Date] AS [TransactionDate]
				  ,[Processed Date] AS [ProcessedDate]
				  ,[Type]
				  ,[Details]
				  ,[Particulars]
				  ,[Code]
				  ,[Reference]
				  ,[Amount]
				  ,[Balance]
				  ,[To/From Account Number] AS [ToFromAccountNumber]
				  ,[Conversion Charge] AS [ConversionCharge]
				  ,[Foreign Currency Amount] AS [ForeignCurrencyAmount]
			  FROM [BOOKS].[LoadImportFile] B
			  WHERE B.LoadImportFileId = A.LoadImportFileId
			  FOR XML PATH ('Row'), Type
			  ) 
			AS [TransactionXML],
		BOOKS.CleanStringMoney([Amount]) AS [Amount],
		@ImportUniqueIdentifier
	FROM [BOOKS].[LoadImportFile] A

	INSERT [BOOKS].TransactionLine (TransactionId, AccountId, DepositAmount, WithdrawalAmount)
	SELECT TransactionId, 
		CASE WHEN Amount >= 0 THEN @BankAccountId ELSE 0 END AS [AccountId],
		ABS(Amount) AS [DepositAmount],
		0 AS WithdrawalAmount
		FROM BOOKS.[Transaction] 
		WHERE ImportUniqueIdentifier = @ImportUniqueIdentifier
	UNION ALL
		 SELECT TransactionId, 
		CASE WHEN Amount < 0 THEN @BankAccountId ELSE 0 END AS [AccountId],
		0 AS DepositAmount,
		ABS(Amount) AS [WithdrawalAmount]
		FROM BOOKS.[Transaction] 
		WHERE ImportUniqueIdentifier = @ImportUniqueIdentifier
		ORDER BY TransactionId ASC;



END