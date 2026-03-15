drop function if exists books.get_account_balance_at_date;

create or replace function books.get_account_balance_at_date (n_account_id int, d_date date)
returns decimal(16,2) as $$
declare n_balance decimal(16,2);
begin
/* 
 get the balance for an account at a date, taking the opening balance into account
 */

	
	select sum(gl.debit_amount) - sum(gl.credit_amount) into n_balance
		from books.general_ledger  gl
		WHERE gl.gl_date <= d_date
			and gl.account_id = n_account_id
		group by gl.account_id;
                                   
	select coalesce(n_balance, 0) into n_balance;

	return (n_balance);
end;
$$ language plpgsql;
