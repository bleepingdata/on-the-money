drop function if exists books.process_month_end_mortgage;

create or replace function books.process_month_end_mortgage (n_loan_principal_account_id int4, n_interest_payable_account_id int4, d_month_end_date date)
returns void as $$
declare n_balance numeric(16,2);
begin
/* 
 
  transfer any non-negative mortgage interest payable balances into the related principal account.
  
  this process must run after all transactions for the month have been imported, otherwise 
  unexpected results may happen.
  
 */
	
	select books.get_account_balance_at_date(n_interest_payable_account_id, d_month_end_date) into n_balance;
	
	if (n_balance > 0)
	then
	
		perform books.insert_gl_entry_basic(
			n_gl_type_id:=1::int2, -- JE 
			n_debit_account_id:=n_loan_principal_account_id::int, 
			n_debit_amount:=n_balance::numeric(16,2), 
			n_credit_account_id:=n_interest_payable_account_id::int, 
			n_credit_amount:=n_balance::numeric(16,2), 
			d_gl_date:=d_month_end_date::date, 
			s_memo:='Interest Payable balance to Principal'::varchar);
	
	end if;
	
	return;
end;
$$ language plpgsql;