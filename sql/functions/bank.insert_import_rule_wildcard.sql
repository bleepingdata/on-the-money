DROP FUNCTION IF EXISTS bank.insert_import_rule_wildcard;

-- ============================================================
-- Function : bank.insert_import_rule_wildcard(varchar, varchar,
--              varchar, int2)
-- ============================================================
-- Purpose  : Creates an import rule that matches using a wildcard pattern
--            against all transaction text fields, delegating to
--            bank.insert_import_rule with a default priority of 0.
--
-- Parameters
--   s_account               (varchar) : Debit GL account description.
--   s_other_party_account   (varchar) : Credit GL account description.
--   s_wildcard_field        (varchar) : LIKE pattern matched against any text field.
--   n_priority              (int2)    : Rule priority; defaults to 0 if NULL.
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.insert_import_rule_wildcard(
--       s_account             := 'Utilities',
--       s_other_party_account := 'ANZ Cheque',
--       s_wildcard_field      := '%VECTOR%',
--       n_priority            := NULL
--   );
--
-- Dependencies
--   Functions : bank.insert_import_rule
-- ============================================================
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