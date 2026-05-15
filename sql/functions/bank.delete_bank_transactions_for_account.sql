DROP FUNCTION IF EXISTS bank.delete_bank_transaction_entries_for_account;

-- ============================================================
-- Function : bank.delete_bank_transaction_entries_for_account(int4, date, date)
-- ============================================================
-- Purpose  : Deletes all bank transactions for a given account
--            within an inclusive date range.
--
-- Parameters
--   n_bank_account_id  (int4) : The bank account to delete transactions for.
--   d_start_date       (date) : Start of the date range (inclusive).
--   d_end_date         (date) : End of the date range (inclusive).
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.delete_bank_transaction_entries_for_account(1, '2024-01-01', '2024-01-31');
--
-- Dependencies
--   Tables    : bank.transaction
-- ============================================================
 CREATE OR REPLACE FUNCTION bank.delete_bank_transaction_entries_for_account ( n_bank_account_id int, d_start_date date, d_end_date date
) RETURNS void AS $$

 BEGIN


	 DELETE FROM bank."transaction"
	 	WHERE bank_account_id = n_bank_account_id 
	 	AND transaction_date >= d_start_date 
	 	AND transaction_date <= d_end_date;

END;

 $$ LANGUAGE plpgsql;