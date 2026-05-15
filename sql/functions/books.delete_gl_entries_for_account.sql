DROP FUNCTION IF EXISTS books.delete_gl_entries_for_account;

-- ============================================================
-- Function : books.delete_gl_entries_for_account(int, date, date)
-- ============================================================
-- Purpose  : Deletes all general ledger entries for a given account within
--            a specified date range, removing entire double-entry groups
--            identified by gl_grouping_id.
--
-- Parameters
--   n_account_id  (int)  : The account ID whose GL entries will be deleted.
--   d_start_date  (date) : Start of the date range (inclusive).
--   d_end_date    (date) : End of the date range (inclusive).
--
-- Returns  : void
--
-- Usage
--   PERFORM books.delete_gl_entries_for_account(10, '2024-01-01', '2024-01-31');
--
-- Dependencies
--   Tables    : books.general_ledger
-- ============================================================
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