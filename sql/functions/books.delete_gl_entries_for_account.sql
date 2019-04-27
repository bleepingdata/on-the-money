drop
	function if exists books.delete_gl_entries_for_account;

 create
or replace
function books.delete_gl_entries_for_account ( n_account_id int, d_start_date date, d_end_date date
) returns void as $$

 begin

	 with groups_to_delete as
	 (select gl.gl_grouping_id from books.general_ledger gl
	 	where gl.account_id = n_account_id 
	 	and gl.gl_date >= d_start_date 
	 	and gl.gl_date <= d_end_date)
	  delete from books.general_ledger gl
	  using groups_to_delete 
	  where gl.gl_grouping_id = groups_to_delete.gl_grouping_id;
	  
end;

 $$ language plpgsql;