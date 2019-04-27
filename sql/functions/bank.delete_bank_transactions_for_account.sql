drop
	function if exists bank.delete_bank_transaction_entries_for_account;

 create
or replace
function bank.delete_bank_transaction_entries_for_account ( n_account_id int, d_start_date date, d_end_date date
) returns void as $$

 begin


	 delete from bank."transaction"
	 	where account_id = n_account_id 
	 	and transaction_date >= d_start_date 
	 	and transaction_date <= d_end_date;

end;

 $$ language plpgsql;