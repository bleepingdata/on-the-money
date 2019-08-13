drop function if exists bank.process_import_rules_from_bank_import();

create or replace function bank.process_import_rules_from_bank_import (n_import_identifier int4)
RETURNS void AS $$
begin
	
	
	perform 
		(bank.process_import_rules_for_transaction(transaction_id))
		from bank.transaction where import_identifier = n_import_identifier;
	
END;
$$ language plpgsql;