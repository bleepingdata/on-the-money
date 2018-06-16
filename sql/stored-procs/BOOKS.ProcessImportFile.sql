USE OnTheMoney
GO
DROP PROC BOOKS.ProcessImportFile
GO
CREATE PROC BOOKS.ProcessImportFile @BankAccountNumber NVARCHAR(56) = NULL, @BankAccountDescription NVARCHAR(50) = NULL
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