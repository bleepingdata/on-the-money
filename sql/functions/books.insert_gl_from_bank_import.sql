drop
	function if exists books.insert_gl_from_bank_import;

 create
or replace
function books.insert_gl_from_bank_import ( n_import_identifier int8
) returns void as $$

 begin

	 with gl_grouping_ids_to_purge as
	 (select gl.gl_grouping_id
	 	from books.general_ledger gl
	 		inner join bank."transaction" t on gl.account_id = t.account_id
	 			and t.import_identifier=n_import_identifier)
	 delete from books.general_ledger gl
	 	using gl_grouping_ids_to_purge p 
	 	where gl.gl_grouping_id = p.gl_grouping_id;
	 
		perform 
		(books.insert_gl_entry_from_bank_transaction(transaction_id))
		from bank.transaction where import_identifier = n_import_identifier;


end;

 $$ language plpgsql;