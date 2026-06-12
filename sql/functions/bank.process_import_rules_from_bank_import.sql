DROP FUNCTION IF EXISTS bank.process_import_rules_from_bank_import();

-- ============================================================
-- Function : bank.process_import_rules_from_bank_import(int4)
-- ============================================================
-- Purpose  : Applies import rule matching to every transaction in a given
--            import batch by iterating over all transactions with the
--            specified import_identifier.
--
-- Parameters
--   n_import_identifier  (int4) : The import batch identifier returned by
--                                 the insert_bank_transaction_from_* functions.
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.process_import_rules_from_bank_import(42);
--
-- Dependencies
--   Tables    : bank.transaction
--   Functions : bank.process_import_rules_for_transaction
-- ============================================================
CREATE OR REPLACE FUNCTION bank.process_import_rules_from_bank_import (n_import_identifier int4)
RETURNS void AS $$
BEGIN
	
	
	PERFORM 
		(bank.process_import_rules_for_transaction(transaction_id))
		FROM bank.transaction WHERE import_identifier = n_import_identifier;
	
END;
$$ LANGUAGE plpgsql;