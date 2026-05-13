DROP FUNCTION IF EXISTS books.insert_gl_from_bank_import;

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