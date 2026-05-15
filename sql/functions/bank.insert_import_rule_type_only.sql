DROP FUNCTION IF EXISTS bank.insert_import_rule_type_only;

-- ============================================================
-- Function : bank.insert_import_rule_type_only(varchar, varchar,
--              varchar, int2)
-- ============================================================
-- Purpose  : Creates an import rule that matches solely on transaction type,
--            with no bank account filter, delegating to bank.insert_import_rule.
--            Uses a very low default priority so it is overridden by more
--            specific rules.
--
-- Parameters
--   s_account               (varchar) : Debit GL account description.
--   s_other_party_account   (varchar) : Credit GL account description.
--   s_type                  (varchar) : Transaction type field to match.
--   n_priority              (int2)    : Rule priority; defaults to -32768 if NULL.
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.insert_import_rule_type_only(
--       s_account             := 'Bank Fees',
--       s_other_party_account := 'ANZ Cheque',
--       s_type                := 'FEE',
--       n_priority            := NULL
--   );
--
-- Dependencies
--   Functions : bank.insert_import_rule
-- ============================================================
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