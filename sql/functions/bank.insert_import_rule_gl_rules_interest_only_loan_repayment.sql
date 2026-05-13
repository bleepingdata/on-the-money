DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_interest_only_loan_repayment;

CREATE OR REPLACE FUNCTION bank.insert_import_rule_gl_rules_interest_only_loan_repayment
	(s_interest_payable_account varchar(50),
	s_cash_account varchar(50),
	n_priority smallint DEFAULT 0,
	s_bank_account varchar(50) DEFAULT NULL,
	s_type varchar(50) DEFAULT NULL,
	s_other_party_bank_account_number varchar(56) DEFAULT NULL,
	s_details varchar(50) DEFAULT NULL,
	s_particulars varchar(50) DEFAULT NULL,
	s_code varchar(50) DEFAULT NULL,
	s_reference varchar(50) DEFAULT NULL,
    s_ofx_name varchar(50) DEFAULT NULL,
	s_ofx_memo varchar(255) DEFAULT NULL,
	s_wildcard_field varchar(50) DEFAULT NULL
	)
RETURNS void AS $$
DECLARE n_import_rule_type_id SMALLINT;
n_interest_payable_account_id int;
n_cash_account_id int;
n_import_rule_id int;
BEGIN
   
    SELECT account_id INTO n_interest_payable_account_id FROM books.account WHERE description = s_interest_payable_account;
    SELECT account_id INTO n_cash_account_id FROM books.account WHERE description = s_cash_account;
   
	IF (n_interest_payable_account_id IS NULL OR n_cash_account_id IS NULL)
	THEN 
		RAISE EXCEPTION 'unable to insert import rule because interest payable account %s or cash account %s cannot be found', s_interest_payable_account, s_cash_account;
		RETURN;
	END IF;

	SELECT bank.insert_import_rule(s_import_rule_type:='interest-only-loan-repayment', n_priority:=n_priority) INTO n_import_rule_id;

	IF n_import_rule_id IS NULL
	THEN 
		RAISE EXCEPTION 'Unable to add row to bank.import_rule for some reason';
		RETURN;
	END IF;

	PERFORM bank.insert_import_rule_fields_to_match(
		n_import_rule_id:=n_import_rule_id, 
		s_bank_account:=s_bank_account,
		s_type:=s_type, 
		s_other_party_bank_account_number:=s_other_party_bank_account_number, 
		s_details:=s_details, 
		s_particulars:=s_particulars, 
		s_code:=s_code,
		s_reference:=s_reference,
		s_ofx_name:=s_ofx_name, 
		s_ofx_memo:=s_ofx_memo,
		s_wildcard_field:=s_wildcard_field);

	INSERT INTO bank.import_rule_gl_matrix (import_rule_id, debit_account_id_1, credit_account_id_1)
		VALUES (n_import_rule_id, 
				n_interest_payable_account_id, 
				n_cash_account_id);
		
	RETURN;
END;
$$ LANGUAGE plpgsql;