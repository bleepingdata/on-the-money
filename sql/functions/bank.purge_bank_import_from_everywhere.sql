DROP FUNCTION IF EXISTS bank.purge_bank_import_from_everywhere;

-- ============================================================
-- Function : bank.purge_bank_import_from_everywhere(int4)
-- ============================================================
-- Purpose  : Completely removes an import batch and all associated general
--            ledger entries, then refreshes the account summary fact table
--            to reflect the deletion.
--
-- Parameters
--   n_import_identifier  (int4) : The import batch identifier to purge.
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.purge_bank_import_from_everywhere(42);
--
-- Dependencies
--   Tables    : bank.transaction, books.general_ledger
--   Functions : fact.populate_account_summary_by_month
-- ============================================================
 CREATE OR REPLACE FUNCTION bank.purge_bank_import_from_everywhere ( n_import_identifier int4 
) RETURNS void AS $$

 BEGIN


	 WITH transactions_to_delete AS
	 (SELECT transaction_id FROM bank.transaction WHERE import_identifier = n_import_identifier )
	  DELETE FROM books.general_ledger gl
	  USING transactions_to_delete 
	  WHERE gl.bank_transaction_id = transactions_to_delete.transaction_id;
	  
	 
	 DELETE FROM bank."transaction"
	 	WHERE import_identifier = n_import_identifier;
	 
	 PERFORM fact.populate_account_summary_by_month();

END;

 $$ LANGUAGE plpgsql;