DROP FUNCTION IF EXISTS bank.insert_import_rule_fields_to_match;

CREATE OR REPLACE FUNCTION bank.insert_import_rule_fields_to_match
	(n_import_rule_id int4,
	s_bank_account varchar(50) DEFAULT NULL,
	b_is_deposit boolean DEFAULT NULL,
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
DECLARE n_bank_account_id int4;
BEGIN
   	
	SELECT bank_account_id INTO n_bank_account_id FROM bank.account WHERE description = s_bank_account;
    
	INSERT INTO bank.import_rule_fields_to_match(import_rule_id, bank_account_id, is_deposit, type, other_party_bank_account_number, details, particulars, code, reference, ofx_name, ofx_memo, wildcard_field)
	 VALUES (n_import_rule_id, n_bank_account_id, b_is_deposit, s_type, s_other_party_bank_account_number, s_details, s_particulars, s_code, s_reference, s_ofx_name, s_ofx_memo, s_wildcard_field);

	RETURN;

END;
$$ LANGUAGE plpgsql;