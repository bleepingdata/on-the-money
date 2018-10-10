drop function if exists books.calculate_balance;

create or replace function books.calculate_balance (n_accountid int)
returns table (accountid_ret int, deposit_amount_total_ret numeric (16,2), withdrawal_amount_total_ret numeric(16,2)) as $$
declare d_deposit_amount_total numeric(16,2);
d_withdrawal_amount_total numeric(16,2);
begin
/* 
 get the balance for an account or accounts, taking the opening balance into account
 */
	
	select sum(depositamount)
	into d_deposit_amount_total
	from books.transaction t
		inner join books.transactionline tl on t.transactionid = tl.transactionid
		inner join books.account a on tl.accountid = a.accountid
		where tl.accountid = n_accountid
		and coalesce(t.bankprocesseddate, '2100-01-01') >= a.openingbalancedate;
		
	select sum(withdrawalamount)
	into d_withdrawal_amount_total
	from books.transaction t
		inner join books.transactionline tl on t.transactionid = tl.transactionid
		inner join books.account a on tl.accountid = a.accountid
		where tl.accountid = n_accountid
		and coalesce(t.bankprocesseddate, '2100-01-01') >= a.openingbalancedate;
	
	update books.account set balance = openingbalance + (coalesce(d_deposit_amount_total,0) - coalesce(d_withdrawal_amount_total,0)) 
			where accountid = n_accountid;

	return query select n_accountid, coalesce(d_deposit_amount_total,0), coalesce(d_withdrawal_amount_total,0);

end;
$$ language plpgsql;