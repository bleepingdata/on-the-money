create or replace function books.get_account_balance_at_date (n_accountid int, d_date date)
returns table (ret_accountid int, ret_date date, ret_balance numeric(16,2))
as $$
declare n_opening_balance numeric(16,2);
n_deposit_amount_total numeric(16,2);
n_withdrawal_amount_total numeric(16,2);
begin
/* 
 get the balance for an account at a date, taking the opening balance into account
 */

       select openingbalance into n_opening_balance
       from books.account where accountid = n_accountid;

		select sum(depositamount) 
		into n_deposit_amount_total
							from books.transaction t
								inner join books.transactionline tl on t.transactionid = tl.transactionid
                                inner join books.account a  on tl.accountid = a.accountid
								where coalesce(t.bankprocesseddate, '2100-01-01') >= a.openingbalancedate
                                    and a.accountid = n_accountid
                                    and t.bankprocesseddate <= d_date;
                                   
		select sum(withdrawalamount)
		into n_withdrawal_amount_total
							from books.transaction t
								inner join books.transactionline tl on t.transactionid = tl.transactionid
								inner join books.account a  on tl.accountid = a.accountid
								where coalesce(t.bankprocesseddate, '2100-01-01') >= a.openingbalancedate
                                    and a.accountid = n_accountid
                                    and t.bankprocesseddate <= d_date;


return query
select n_accountid, d_date, (n_opening_balance) + (n_deposit_amount_total - n_withdrawal_amount_total) as balance;
--into ret_accountid, ret_date, ret_balance;

end;
$$ language plpgsql;
