CREATE or replace function BOOKS.ProcessImportFile (sBankAccountNumber VARCHAR(56) = NULL, 
		sBankAccountDescription VARCHAR(50) = NULL,
		bRemoveOverlappingTransactions BOOLEAN = FALSE /* remove txs from same account for the same date(s) */
		)
returns VOID as $$
declare 
	nBankAccountId INT;
	nUniqueIdentifier INT;
BEGIN
-- Process a bank file from ANZ. The file contents must already exist in BOOKS.LoadImportFile table. Parameters determine which account the
-- transactions will be recorded against

--	IF @BankAccountNumber IS NULL AND @BankAccountDescription IS NULL
--	BEGIN
--		RAISERROR('All parameters for proc are null or missing', 15,1);
--	END

	-- get the bank account id
	SELECT AccountId 
	into nBankAccountId
		FROM BOOKS.Account 
		WHERE BankAccountNumber = coalesce(sBankAccountNumber, BankAccountNumber) 
			AND Description = coalesce(sBankAccountDescription, Description)
			AND (sBankAccountNumber IS NOT NULL OR sBankAccountDescription IS NOT NULL);
--	IF BankAccountId IS null then 
--		RAISERROR('Unable to find BOOKS.Account entry for bank account %s, description %s', 15,1, @BankAccountNumber, @BankAccountDescription);
--	end if;

	select BOOKS.ImportSeq()
	into nUniqueIdentifier;
	
	-- add to staging tables
	INSERT into BOOKS.TransactionStaging (BankTransactionDate, BankProcessedDate, Amount, ImportUniqueIdentifier, Type, Details, Particulars, Code, Reference)
		SELECT
			cast("Transaction Date" as DATE) BankTransactionDate, cast ("Processed Date" as date) AS BankProcessedDate,
			/*(SELECT LoadImportFileId
					  ,"Transaction Date" AS TransactionDate
					  ,"Processed Date" AS ProcessedDate
					  ,Type
					  ,Details
					  ,Particulars
					  ,Code
					  ,Reference
					  ,Amount
					  ,Balance
					  ,"To/From Account Number" AS ToFromAccountNumber
					  ,"Conversion Charge" AS ConversionCharge
					  ,"Foreign Currency Amount" AS ForeignCurrencyAmount
				  FROM BOOKS.LoadImportFile B
				  WHERE B.LoadImportFileId = A.LoadImportFileId
				  FOR XML PATH ('Row'), Type
				  ) 
				AS TransactionXML,*/
			BOOKS.CleanStringMoney(Amount) AS Amount,
			nUniqueIdentifier,
			Type,
			Details,
			Particulars,
			Code,
			Reference
		FROM BOOKS.LoadImportFile A;

	INSERT into BOOKS.TransactionLineStaging (TransactionStagingId, AccountId, DepositAmount, WithdrawalAmount)
		SELECT TransactionStagingId, 
				CASE WHEN Amount >= 0 THEN nBankAccountId ELSE 0 END AS AccountId,
				ABS(Amount) AS DepositAmount,
				0 AS WithdrawalAmount
			FROM BOOKS.TransactionStaging 
			WHERE ImportUniqueIdentifier = nUniqueIdentifier
		UNION ALL
		SELECT TransactionStagingId, 
				CASE WHEN Amount < 0 THEN nBankAccountId ELSE 0 END AS AccountId,
				0 AS DepositAmount,
				ABS(Amount) AS WithdrawalAmount
			FROM BOOKS.TransactionStaging 
			WHERE ImportUniqueIdentifier = nUniqueIdentifier
			ORDER BY TransactionStagingId ASC;
--
--	IF bRemoveOverlappingTransactions == true
--	BEGIN
--		DECLARE @TransactionIdsToDelete TABLE (TransactionId BIGINT PRIMARY KEY CLUSTERED);
--
--		INSERT @TransactionIdsToDelete (TransactionId) 
--		SELECT DISTINCT t.TransactionId
--			FROM BOOKS.Transaction t
--				INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
--				WHERE tl.AccountId = @BankAccountId AND t.BankTransactionDate 
--					IN (SELECT BankTransactionDate 
--							FROM BOOKS.TransactionStaging 
--							WHERE ImportUniqueIdentifier = @ImportUniqueIdentifier);
--
--		DELETE BOOKS.TransactionLine WHERE TransactionId IN (SELECT TransactionId FROM @TransactionIdsToDelete);
--		DELETE BOOKS.Transaction WHERE TransactionId IN (SELECT TransactionId FROM @TransactionIdsToDelete);
--	END
--	ELSE
--	BEGIN
--		-- check staging tables (are we duplicating transactions, etc)
--		DECLARE @MAX_ALLOWABLE_DUPES INT = 0, @Dupes INT = 0;
--
--		
--		SELECT @Dupes = COUNT(*) FROM
--		(
--		SELECT ts.BankTransactionDate, ts.BankProcessedDate, tls.DepositAmount, tls.WithdrawalAmount, tls.AccountId
--			FROM BOOKS.TransactionStaging ts
--			INNER JOIN BOOKS.TransactionLineStaging tls ON ts.TransactionStagingId = tls.TransactionStagingId
--		INTERSECT 
--		SELECT t.BankTransactionDate, t.BankProcessedDate, tl.DepositAmount, tl.WithdrawalAmount, tl.AccountId
--			FROM BOOKS.Transaction t
--			INNER JOIN BOOKS.TransactionLine tl ON t.TransactionId = tl.TransactionId
--		) dupes
--
--		IF @Dupes > @MAX_ALLOWABLE_DUPES
--		BEGIN
--			RAISERROR('Unable to import transactions because %i duplicates were found in BOOKS.TransactionLineStaging', 15, 1, @Dupes) WITH NOWAIT;
--			RETURN 1;
--		END
--	END

	-- Import into Transaction tables
	INSERT into BOOKS.Transaction (BankTransactionDate, BankProcessedDate, TransactionXML, Amount, ImportUniqueIdentifier, Type, Details, Particulars, Code, Reference)
	SELECT 
		BankTransactionDate, 
		BankProcessedDate,
		TransactionXML,
		Amount,
		ImportUniqueIdentifier,
		Type,
		Details,
		Particulars,
		Code,
		Reference
		FROM BOOKS.TransactionStaging A;

	INSERT into BOOKS.TransactionLine (TransactionId, AccountId, DepositAmount, WithdrawalAmount)
		SELECT TransactionId, 
			CASE WHEN Amount >= 0 THEN @BankAccountId ELSE 0 END AS AccountId,
			ABS(Amount) AS DepositAmount,
			0 AS WithdrawalAmount
			FROM BOOKS.Transaction 
			WHERE ImportUniqueIdentifier = nUniqueIdentifier
		UNION ALL
		SELECT TransactionId, 
			CASE WHEN Amount < 0 THEN @BankAccountId ELSE 0 END AS AccountId,
			0 AS DepositAmount,
			ABS(Amount) AS WithdrawalAmount
			FROM BOOKS.Transaction 
			WHERE ImportUniqueIdentifier = nUniqueIdentifier
			ORDER BY TransactionId ASC;


END;
$$ LANGUAGE plpgsql;