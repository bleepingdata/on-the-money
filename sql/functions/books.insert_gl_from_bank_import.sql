drop
	function if exists books.insert_gl_from_bank_import;

 create
or replace
function books.insert_gl_from_bank_import ( n_import_identifier int8
) returns void as $$

 begin
	 
		perform 
		(books.insert_gl_entry_from_bank_transaction(transaction_id))
		from bank.transaction where import_identifier = n_import_identifier
		and processed_date is not null;


end;

 $$ language plpgsql;