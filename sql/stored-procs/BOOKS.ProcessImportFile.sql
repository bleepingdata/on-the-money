CREATE or replace function BOOKS.ProcessImportFile (sBankAccountNumber VARCHAR(56) = NULL, 
		sBankAccountDescription VARCHAR(50) = NULL,
		bRemoveOverlappingTransactions BOOLEAN = FALSE /* remove txs from same account for the same date(s) */
		)
returns VOID as $$
declare 
	nBankAccountId INT;
	nImportSeq INT;
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

	select nextval('books.ImportSeq')
	into nImportSeq;
	
	-- add to staging tables
	INSERT into BOOKS.TransactionStaging (BankTransactionDate, BankProcessedDate, transactionxml, amount, ImportSeq, Type, Details, Particulars, Code, Reference)
		SELECT
			cast("Transaction Date" as date), 
			cast ("Processed Date" as date),
			'<xml>blah</xml>',
			cast(A."Amount" as money),--BOOKS.CleanStringMoney(A.Amount),
			nImportSeq,
			"Type",
			"Details",
			"Particulars",
			"Code",
			"Reference"
		FROM BOOKS.LoadImportFile A;

	INSERT into BOOKS.TransactionLineStaging (TransactionStagingId, AccountId, DepositAmount, WithdrawalAmount)
		SELECT TransactionStagingId, 
				CASE WHEN amount >= 0.0 THEN nBankAccountId ELSE 0 END AS AccountId,
				abs("amount") AS DepositAmount,
				0.0 AS WithdrawalAmount
			FROM BOOKS.TransactionStaging 
			WHERE ImportSeq = nImportSeq
		UNION ALL
		SELECT TransactionStagingId, 
				CASE WHEN Amount < 0.0 THEN nBankAccountId ELSE 0 END AS AccountId,
				0.0 AS DepositAmount,
				abs(Amount) AS WithdrawalAmount
			FROM BOOKS.TransactionStaging 
			WHERE ImportSeq = nImportSeq
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
	INSERT into BOOKS.Transaction (BankTransactionDate, BankProcessedDate, TransactionXML, Amount, ImportSeq, Type, Details, Particulars, Code, Reference)
	SELECT 
		BankTransactionDate, 
		BankProcessedDate,
		TransactionXML,
		Amount,
		ImportSeq,
		Type,
		Details,
		Particulars,
		Code,
		Reference
		FROM BOOKS.TransactionStaging A;

	INSERT into BOOKS.TransactionLine (TransactionId, AccountId, DepositAmount, WithdrawalAmount)
		SELECT TransactionId, 
			CASE WHEN Amount >= 0.0 THEN nBankAccountId ELSE 0 END AS AccountId,
			ABS(Amount) AS DepositAmount,
			0.0 AS WithdrawalAmount
			FROM BOOKS.Transaction 
			WHERE ImportSeq = nImportSeq
		UNION ALL
		SELECT TransactionId, 
			CASE WHEN Amount < 0.0 THEN nBankAccountId ELSE 0 END AS AccountId,
			0.0 AS DepositAmount,
			ABS(Amount) AS WithdrawalAmount
			FROM BOOKS.Transaction 
			WHERE ImportSeq = nImportSeq
			ORDER BY TransactionId ASC;


END;
$$ LANGUAGE plpgsql;