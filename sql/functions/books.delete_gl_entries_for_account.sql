DROP FUNCTION IF EXISTS books.delete_gl_entries_for_account;

 CREATE OR REPLACE FUNCTION books.delete_gl_entries_for_account ( n_account_id int, d_start_date date, d_end_date date
) RETURNS void AS $$

 BEGIN

	 WITH groups_to_delete AS
	 (SELECT gl.gl_grouping_id FROM books.general_ledger gl
	 	WHERE gl.account_id = n_account_id 
	 	AND gl.gl_date >= d_start_date 
	 	AND gl.gl_date <= d_end_date)
	  DELETE FROM books.general_ledger gl
	  USING groups_to_delete 
	  WHERE gl.gl_grouping_id = groups_to_delete.gl_grouping_id;
	  
END;

 $$ LANGUAGE plpgsql;