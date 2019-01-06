drop
	function if exists fact.populate_account_summary_by_month;

 create
or replace
function fact.populate_account_summary_by_month() returns void as $$ 
begin 
	
	truncate table
		fact.account_summary_by_month;

 insert
	into
		fact.account_summary_by_month ( accountid, year, month, month_as_date, deposit_amount, withdrawal_amount, deposit_amount_running_total, withdrawal_amount_running_total, balance ) 
		select
			transactions.accountid,
			transactions.year,
			transactions.month,
			transactions.month_as_date,
			transactions.deposit_amount,
			transactions.withdrawal_amount,
			sum ( transactions.deposit_amount ) over ( partition by transactions.accountid order by transactions.year, transactions.month) as deposit_amount_running_total,
			sum ( transactions.withdrawal_amount ) over ( partition by transactions.accountid order by transactions.year, transactions.month) as withdrawal_amount_running_total,
			sum ( transactions.deposit_amount - transactions.withdrawal_amount) over ( partition by transactions.accountid order by transactions.year, transactions.month) as balance
		from
			( select
				tl.accountid, 
				date_part( 'year', t.banktransactiondate ) as year, 
				date_part( 'month', t.banktransactiondate ) as month, 
				date_trunc( 'month', max( t.banktransactiondate )) + interval '1 month' - interval '1 day' as month_as_date, 
				sum(tl.depositamount) as deposit_amount, 
				sum(tl.withdrawalamount) as withdrawal_amount
			from
				books.transaction t
			inner join books.transactionline tl on
				t.transactionid = tl.transactionid
			group by
				tl.accountid, date_part( 'year', t.banktransactiondate ), date_part( 'month', t.banktransactiondate ) 
				) transactions
		order by
			transactions.accountid,
			year,
			month;

 return;


end;

 $$ language plpgsql;