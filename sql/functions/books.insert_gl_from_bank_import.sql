DROP FUNCTION IF EXISTS books.insert_gl_from_bank_import;

-- ============================================================
-- Function : books.insert_gl_from_bank_import(int8)
-- ============================================================
-- Purpose  : Posts GL entries for all transactions belonging to a specific
--            bank import batch, processing them in date order. Calls
--            books.insert_gl_entry_from_bank_transaction for each transaction
--            that has a processed date.
--
-- Parameters
--   n_import_identifier  (int8) : The import batch identifier to process.
--
-- Returns  : void
--
-- Usage
--   PERFORM books.insert_gl_from_bank_import(7);
--
-- Dependencies
--   Tables    : bank.transaction
--   Functions : books.insert_gl_entry_from_bank_transaction
-- ============================================================
 CREATE OR REPLACE FUNCTION books.insert_gl_from_bank_import ( n_import_identifier int8
) RETURNS void AS $$

 BEGIN
	 
		PERFORM 
		(books.insert_gl_entry_from_bank_transaction(transaction_id))
		FROM bank.transaction WHERE import_identifier = n_import_identifier
		AND processed_date IS NOT NULL
		ORDER BY processed_date ASC;


END;

 $$ LANGUAGE plpgsql;