DROP FUNCTION IF EXISTS bank.insert_import_rule_ofx;

-- ============================================================
-- Function : bank.insert_import_rule_ofx(varchar, varchar, varchar,
--              varchar, varchar, varchar, int2)
-- ============================================================
-- Purpose  : Creates an OFX-specific import rule matching on transaction type,
--            OFX name, and OFX memo fields, delegating to bank.insert_import_rule
--            with a default high priority when none is supplied.
--
-- Parameters
--   s_bank_account          (varchar) : Bank account description to associate with the rule.
--   s_account               (varchar) : Debit GL account description.
--   s_other_party_account   (varchar) : Credit GL account description.
--   s_type                  (varchar) : OFX transaction type to match.
--   s_ofx_name              (varchar) : OFX name field to match.
--   s_ofx_memo              (varchar) : OFX memo field to match.
--   n_priority              (int2)    : Rule priority; defaults to 32767 (highest) if NULL.
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.insert_import_rule_ofx(
--       s_bank_account        := 'ANZ Cheque',
--       s_account             := 'Groceries',
--       s_other_party_account := 'ANZ Cheque',
--       s_type                := 'DEBIT',
--       s_ofx_name            := 'COUNTDOWN',
--       s_ofx_memo            := NULL,
--       n_priority            := NULL
--   );
--
-- Dependencies
--   Functions : bank.insert_import_rule
-- ============================================================
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