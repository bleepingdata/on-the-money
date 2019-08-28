drop view if exists fact.bank_account_balance;

create or replace view fact.bank_account_balance
as
with monthly_summary as 
(
 select
	gl.bank_account_id,
	gl.gl_date,
	gl.debit_amount,
	gl.credit_amount
from
	books.general_ledger gl
	where bank_account_id is not null
union all select
	a.bank_account_id,
	d.month_year_date as gl_date,
	0 as debit_amount,
	0 as credit_amount
from
	dimension.dates d
inner join bank.account a on
	d.datekey >= a.open_date
left join books.general_ledger gl on
	d.datekey = gl.gl_date
	and a.bank_account_id = gl.bank_account_id
where
	gl.bank_account_id is null
	and d.datekey >= (
	select
		min(gl_date)
	from
		books.general_ledger)
	and d.month_year_date <= (
	select
		(date_trunc('month', max(gl_date)) + interval '1 month' - interval '1 day')::date
	from
		books.general_ledger)
group by a.bank_account_id, d.month_year_date
)
		select
			transactions.bank_account_id,
			transactions.year,
			transactions.month_number,
			transactions.month_end_date,
			transactions.debit_amount,
			transactions.credit_amount,
			sum ( transactions.debit_amount ) over ( partition by transactions.bank_account_id order by transactions.year, transactions.month_number) as debit_amount_running_total,
			sum ( transactions.credit_amount ) over ( partition by transactions.bank_account_id order by transactions.year, transactions.month_number) as credit_amount_running_total,
			sum ( transactions.debit_amount - transactions.credit_amount) over ( partition by transactions.bank_account_id order by transactions.year, transactions.month_number) as balance
		from
			( select
				bank_account_id, 
				date_part( 'year', gl_date ) as year, 
				date_part( 'month', gl_date ) as month_number, 
				cast(date_trunc( 'month', max( gl_date )) + interval '1 month' - interval '1 day' as date) as month_end_date, 
				sum(debit_amount) as debit_amount, 
				sum(credit_amount) as credit_amount
			from
				monthly_summary
			group by
				bank_account_id, date_part( 'year', gl_date ), date_part( 'month', gl_date ) 
				) transactions
		order by
			transactions.bank_account_id,
			transactions.year,
			transactions.month_number;
