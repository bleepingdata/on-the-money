drop
	function if exists fact.populate_account_summary_by_month;

 create
or replace
function fact.populate_account_summary_by_month() returns void as $$ 
begin 
	
	truncate table
		fact.account_summary_by_month;
with monthly_txn as 
(
 select
	tl.accountid,
	t.banktransactiondate,
	tl.depositamount,
	tl.withdrawalamount
from
	books.transaction t
inner join books.transactionline tl on
	t.transactionid = tl.transactionid
union all select
	a.accountid,
	d.month_year_date as banktransactiondate,
	0 as depositamount,
	0 as withdrawalamount
from
	dimension.dates d
inner join books.account a on
	d.datekey >= a.openingbalancedate
left join books.transaction t on
	d.datekey = t.banktransactiondate
	and a.accountid = t.sourceaccountid
where
	t.sourceaccountid is null
	and d.datekey >= (
	select
		min(banktransactiondate)
	from
		books."transaction")
	and d.month_year_date <= (
	select
		max(banktransactiondate)
	from
		books."transaction")
group by a.accountid, d.month_year_date
)
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
				accountid, 
				date_part( 'year', banktransactiondate ) as year, 
				date_part( 'month', banktransactiondate ) as month, 
				date_trunc( 'month', max( banktransactiondate )) + interval '1 month' - interval '1 day' as month_as_date, 
				sum(depositamount) as deposit_amount, 
				sum(withdrawalamount) as withdrawal_amount
			from
				monthly_txn
			group by
				accountid, date_part( 'year', banktransactiondate ), date_part( 'month', banktransactiondate ) 
				) transactions
		order by
			transactions.accountid,
			year,
			month;

 return;


end;

 $$ language plpgsql;