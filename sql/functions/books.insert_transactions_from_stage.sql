DROP FUNCTION IF EXISTS books.insert_manual_entry(varchar, varchar, date, date, numeric, varchar, varchar, varchar, varchar, varchar);

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