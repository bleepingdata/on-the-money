drop
	function if exists bank.purge_bank_import_from_everywhere;

 create
or replace
function bank.purge_bank_import_from_everywhere ( n_import_identifier int4 
) returns void as $$

 begin


	 with transactions_to_delete as
	 (select transaction_id from bank.transaction where import_identifier = n_import_identifier )
	  delete from books.general_ledger gl
	  using transactions_to_delete 
	  where gl.bank_transaction_id = transactions_to_delete.transaction_id;
	  
	 
	 delete from bank."transaction"
	 	where import_identifier = n_import_identifier;
	 
	 perform fact.populate_account_summary_by_month();

end;

 $$ language plpgsql;