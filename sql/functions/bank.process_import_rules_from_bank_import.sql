DROP FUNCTION IF EXISTS bank.process_import_rules_from_bank_import();

CREATE OR REPLACE FUNCTION bank.process_import_rules_from_bank_import (n_import_identifier int4)
RETURNS void AS $$
BEGIN
	
	
	PERFORM 
		(bank.process_import_rules_for_transaction(transaction_id))
		FROM bank.transaction WHERE import_identifier = n_import_identifier;
	
END;
$$ LANGUAGE plpgsql;