DROP FUNCTION IF EXISTS books.insert_gl_entry_basic;

CREATE OR REPLACE FUNCTION books.insert_gl_entry_basic (n_gl_type_id int2, 
n_debit_account_id int,
n_debit_amount numeric(16,2),
n_credit_account_id int,
n_credit_amount numeric(16,2),
d_gl_date date,
n_debit_account_id_2 int DEFAULT NULL,
n_debit_amount_2 numeric(16,2) DEFAULT NULL,
n_credit_account_id_2 int DEFAULT NULL,
n_credit_amount_2 numeric(16,2) DEFAULT NULL,
s_memo varchar(256) DEFAULT NULL,
n_bank_account_id int4 DEFAULT NULL,
b_bank_account_is_debit boolean DEFAULT NULL,
n_bank_transaction_id int8 DEFAULT NULL,
n_matched_import_rule_id int4 DEFAULT NULL) 
RETURNS int AS $$ 
DECLARE n_gl_grouping_id int8;
BEGIN

	SELECT
	nextval('books.gl_grouping_seq') INTO
		n_gl_grouping_id;


	IF (n_debit_account_id IS NULL OR n_credit_account_id IS NULL)
	THEN
		RAISE EXCEPTION 'Missing n_debit_account_id or n_credit_account_id'
    	USING HINT = 'Please check your parameters';
    END IF;
    
    IF ((n_debit_amount + COALESCE(n_debit_amount_2,0)) <> (n_credit_amount + COALESCE(n_credit_amount_2,0)))
    THEN
	    RAISE EXCEPTION 'Sum of credits does not equal sum of debits'
    	USING HINT = 'Please check your parameters';
    END IF;
   
    IF ((n_debit_account_id_2 IS NOT NULL AND n_debit_amount_2 IS NULL) 
    	OR (n_debit_account_id_2 IS NULL AND n_debit_amount_2 IS NOT NULL))
    THEN
    	RAISE EXCEPTION 'Missing parameter for debit account 2 or debit amount 2'
    	USING HINT = 'Please check your parameters';
    END IF;
    IF ((n_credit_account_id_2 IS NOT NULL AND n_credit_amount_2 IS NULL) 
    	OR (n_credit_account_id_2 IS NULL AND n_credit_amount_2 IS NOT NULL))
    THEN
    	RAISE EXCEPTION 'Missing parameter for credit account 2 or credit amount 2'
    	USING HINT = 'Please check your parameters';
    END IF;
    
	INSERT INTO
		books.general_ledger ( gl_type_id,
		gl_date,
		gl_grouping_id,
		account_id,
		debit_amount,
		credit_amount,
		memo,
		bank_account_id,
		bank_transaction_id,
		matched_import_rule_id)
	VALUES ( n_gl_type_id,
 	d_gl_date,
	n_gl_grouping_id,
	n_debit_account_id,
	n_debit_amount,
	0,
	s_memo,
	CASE WHEN b_bank_account_is_debit = TRUE THEN n_bank_account_id ELSE NULL END,
	n_bank_transaction_id,
    n_matched_import_rule_id);
	
	INSERT INTO
		books.general_ledger ( gl_type_id,
		gl_date,
		gl_grouping_id,
		account_id,
		debit_amount,
		credit_amount,
		memo,
		bank_account_id,
		bank_transaction_id,
		matched_import_rule_id)
	VALUES ( n_gl_type_id,
	 d_gl_date,
	n_gl_grouping_id,
	n_credit_account_id,
	0,
	n_credit_amount,
	s_memo,
	CASE WHEN b_bank_account_is_debit = FALSE THEN n_bank_account_id ELSE NULL END,
	n_bank_transaction_id,
    n_matched_import_rule_id);
	
    IF (n_debit_account_id_2 IS NOT NULL AND n_debit_amount_2 IS NOT NULL)
    THEN
		INSERT INTO
			books.general_ledger ( gl_type_id,
			gl_date,
			gl_grouping_id,
			account_id,
			debit_amount,
			credit_amount,
			memo,
			bank_account_id,
			bank_transaction_id,
			matched_import_rule_id)
		VALUES ( n_gl_type_id,
	 	d_gl_date,
		n_gl_grouping_id,
		n_debit_account_id_2,
		n_debit_amount_2,
		0,
		s_memo,
		CASE WHEN b_bank_account_is_debit = TRUE THEN n_bank_account_id ELSE NULL END,
		n_bank_transaction_id,
	    n_matched_import_rule_id);
    END IF;
   
    
	IF (n_credit_account_id_2 IS NOT NULL AND n_credit_amount_2 IS NOT NULL)
    THEN
		INSERT INTO
			books.general_ledger ( gl_type_id,
			gl_date,
			gl_grouping_id,
			account_id,
			debit_amount,
			credit_amount,
			memo,
			bank_account_id,
			bank_transaction_id,
			matched_import_rule_id)
		VALUES ( n_gl_type_id,
		 d_gl_date,
		n_gl_grouping_id,
		n_credit_account_id_2,
		0,
		n_credit_amount_2,
		s_memo,
		CASE WHEN b_bank_account_is_debit = FALSE THEN n_bank_account_id ELSE NULL END,
		n_bank_transaction_id,
    	n_matched_import_rule_id);    
    END IF;
    
    RETURN 1;
END;

$$ LANGUAGE plpgsql;