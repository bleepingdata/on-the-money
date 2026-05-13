DROP FUNCTION IF EXISTS bank.insert_import_rule_wildcard;

CREATE OR REPLACE FUNCTION bank.insert_import_rule_wildcard
	(s_account varchar(50),
	s_other_party_account varchar(50),
	s_wildcard_field varchar(50),
	n_priority int2 DEFAULT NULL)
RETURNS void AS $$
DECLARE 
n_account_id int;
n_other_party_account_id int;
n_import_rule_id int;
BEGIN

	IF n_priority IS NULL
    THEN
    	n_priority=0;  -- by default, wildcard rules should have a low priority in comparison to other rules
    END IF;
   
	PERFORM bank.insert_import_rule(s_bank_account:=NULL,
	s_import_rule_type:='Standard',
	s_account:=s_account,
	s_other_party_account:=s_other_party_account,
    s_wildcard_field:=s_wildcard_field,
    n_priority:=n_priority);
	
	RETURN;
END;
$$ LANGUAGE plpgsql;