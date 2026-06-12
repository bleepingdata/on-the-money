DROP FUNCTION IF EXISTS bank.insert_import_rule_fields_to_match;

-- ============================================================
-- Function : bank.insert_import_rule_fields_to_match(int4, varchar, boolean,
--              varchar, varchar, varchar, varchar, varchar, varchar,
--              varchar, varchar, varchar)
-- ============================================================
-- Purpose  : Inserts the transaction-field matching criteria for an import
--            rule, resolving the bank account description to an ID.
--            All filter fields are optional; NULL means "match any value".
--
-- Parameters
--   n_import_rule_id                   (int4)    : The parent import rule ID.
--   s_bank_account                     (varchar) : Bank account description to restrict the rule to.
--   b_is_deposit                       (boolean) : TRUE = deposits only, FALSE = withdrawals only.
--   s_type                             (varchar) : Transaction type field to match.
--   s_other_party_bank_account_number  (varchar) : Other party account number to match.
--   s_details                          (varchar) : Details field pattern (supports LIKE).
--   s_particulars                      (varchar) : Particulars field pattern (supports LIKE).
--   s_code                             (varchar) : Code field pattern (supports LIKE).
--   s_reference                        (varchar) : Reference field pattern (supports LIKE).
--   s_ofx_name                         (varchar) : OFX name field pattern (supports LIKE).
--   s_ofx_memo                         (varchar) : OFX memo field pattern (supports LIKE).
--   s_wildcard_field                   (varchar) : Pattern matched across all text fields (supports LIKE).
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.insert_import_rule_fields_to_match(
--       n_import_rule_id := 5,
--       s_bank_account   := 'ANZ Cheque',
--       s_details        := '%COUNTDOWN%'
--   );
--
-- Dependencies
--   Tables    : bank.account, bank.import_rule_fields_to_match
-- ============================================================
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