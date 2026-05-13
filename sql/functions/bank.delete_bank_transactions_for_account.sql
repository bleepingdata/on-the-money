DROP FUNCTION IF EXISTS bank.delete_bank_transaction_entries_for_account;

 CREATE OR REPLACE FUNCTION bank.delete_bank_transaction_entries_for_account ( n_bank_account_id int, d_start_date date, d_end_date date
) RETURNS void AS $$

 BEGIN


	 DELETE FROM bank."transaction"
	 	WHERE bank_account_id = n_bank_account_id 
	 	AND transaction_date >= d_start_date 
	 	AND transaction_date <= d_end_date;

END;

 $$ LANGUAGE plpgsql;