DROP FUNCTION IF EXISTS bank.insert_import_rule_ofx;

CREATE OR REPLACE FUNCTION bank.insert_import_rule_ofx
	(s_bank_account varchar(50),
	s_account varchar(50),
	s_other_party_account varchar(50),
	s_type varchar(50),
	s_ofx_name varchar(50),
	s_ofx_memo varchar(255),
	n_priority int2)
RETURNS void AS $$
DECLARE n_bank_account_id int;
n_account_id int;
n_other_party_account_id int;
n_import_rule_id int;
BEGIN


	IF n_priority IS NULL
    THEN
    	n_priority=32767;  -- by default, ofx  rules should have a high priority
    END IF;

	PERFORM bank.insert_import_rule(s_import_rule_type:='Standard',
	s_bank_account:=s_bank_account,
	s_account:=s_account,
	s_other_party_account:=s_other_party_account,
    s_type:=s_type,
    s_ofx_name:=s_ofx_name,
    s_ofx_memo:=s_ofx_memo,
    n_priority:=n_priority);

	RETURN;
END;
$$ LANGUAGE plpgsql;