DROP FUNCTION IF EXISTS books.insert_manual_entry(varchar, varchar, date, date, numeric, varchar, varchar, varchar, varchar, varchar);

-- ============================================================
-- Function : books.insert_manual_entry(varchar, varchar, date, date,
--              numeric, varchar, varchar, varchar, varchar, varchar)
-- ============================================================
-- Purpose  : Inserts a manually-created bank transaction into the staging
--            table (transactionstaging) by resolving from/to account
--            descriptions to IDs, then returns the new staging record ID
--            for downstream processing.
--
-- Parameters
--   s_from_account          (varchar) : Description of the source account.
--   s_to_account            (varchar) : Description of the destination account.
--   d_bank_transaction_date (date)    : The transaction date.
--   d_bank_processed_date   (date)    : The bank processed date.
--   n_amount                (numeric) : Transaction amount.
--   s_type                  (varchar) : Transaction type.
--   s_details               (varchar) : Transaction details/narration.
--   s_particulars           (varchar) : Particulars field.
--   s_code                  (varchar) : Code field.
--   s_reference             (varchar) : Reference field.
--
-- Returns  : int — the new transactionstagingid on success, or 0 if either
--            account cannot be found.
--
-- Usage
--   SELECT books.insert_manual_entry(
--     'Bank Cheque Account', 'Mortgage Account',
--     '2024-01-15', '2024-01-15',
--     1000.00, 'Transfer', 'Mortgage payment', '', '', ''
--   );
--
-- Dependencies
--   Tables    : books.account, books.transactionstaging, books.transactionlinestaging
-- ============================================================
CREATE OR REPLACE FUNCTION books.insert_manual_entry
	(s_from_account varchar(50),
	s_to_account varchar(50),
	d_bank_transaction_date date,
	d_bank_processed_date date,
	n_amount numeric(16,2),
	s_type varchar(50),
	s_details varchar(50),
	s_particulars varchar(50),
	s_code varchar(50),
	s_reference varchar(50))
RETURNS int AS $$
DECLARE n_from_accountid int;
n_to_accountid int;
n_transactionstagingid int8;
BEGIN

	SELECT accountid INTO n_from_accountid FROM books.account WHERE description = s_from_account;
	SELECT accountid INTO n_to_accountid FROM books.account WHERE description = s_to_account;

    DELETE FROM books.transactionlinestaging;
    DELETE FROM books.transactionstaging;
   
	IF n_from_accountid IS NULL OR n_to_accountid IS NULL
	THEN 
		RAISE EXCEPTION 'unable to insert manual transaction because either fromaccount %s or toaccount %s cannot be found', s_from_account, s_to_account;
		RETURN 0;
	END IF;

	INSERT INTO books.transactionstaging (sourceaccountid, 
				banktransactiondate, 
				bankprocesseddate, 
				transactionxml, 
				amount, 
				type, 
				details, 
				particulars, 
				code, 
				reference,
				importseq,
				importdatetime)
		VALUES (n_from_accountid, 
			d_bank_transaction_date, 
			d_bank_processed_date, 
			'', 
			n_amount, s_type, s_details, s_particulars, s_code, s_reference,
			1,
			now())
	 RETURNING transactionstagingid INTO n_transactionstagingid;
	

	
	RETURN n_transactionstagingid;
END;
$$ LANGUAGE plpgsql;