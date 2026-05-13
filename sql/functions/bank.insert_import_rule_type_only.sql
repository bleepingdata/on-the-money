DROP FUNCTION IF EXISTS bank.insert_import_rule_type_only;

CREATE OR REPLACE FUNCTION bank.insert_import_rule_type_only
	(s_account varchar(50),
	s_other_party_account varchar(50),
	s_type varchar(50),
	n_priority int2)
RETURNS void AS $$
DECLARE 
n_other_party_account_id int;
n_import_rule_id int;
BEGIN

	IF n_priority IS NULL
    THEN
    	SELECT -32768 INTO n_priority;  -- by default, wildcard rules should have a very low priority in comparison to other rules
    END IF;
   
	PERFORM bank.insert_import_rule(s_bank_account:=NULL,
	s_import_rule_type:='Standard',
	s_account:=s_account,
	s_other_party_account:=s_other_party_account,
    s_type:=s_type,
    n_priority:=n_priority);
	
	RETURN;
END;
$$ LANGUAGE plpgsql;