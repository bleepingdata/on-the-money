drop
	function if exists fact.populate_account_summary_by_month;

 create
or replace
function fact.populate_account_summary_by_month() returns void as $$ 
begin 
	
	truncate table
		fact.account_summary_by_month;
	
with monthly_summary as 
(
 select
	gl.account_id,
	gl.gl_date,
	gl.debit_amount,
	gl.credit_amount
from
	books.general_ledger gl
union all select
	a.account_id,
	d.month_year_date as gl_date,
	0 as debit_amount,
	0 as credit_amount
from
	dimension.dates d
inner join books.account a on
	d.datekey >= a.open_date
left join books.general_ledger gl on
	d.datekey = gl.gl_date
	and a.account_id = gl.account_id
where
	gl.account_id is null
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
group by a.account_id, d.month_year_date
)
 insert
	into
		fact.account_summary_by_month ( account_id, year, month_number, month_end_date, debit_amount, credit_amount, debit_amount_running_total, credit_amount_running_total, balance ) 
		select
			transactions.account_id,
			transactions.year,
			transactions.month_number,
			transactions.month_end_date,
			transactions.debit_amount,
			transactions.credit_amount,
			sum ( transactions.debit_amount ) over ( partition by transactions.account_id order by transactions.year, transactions.month_number) as debit_amount_running_total,
			sum ( transactions.credit_amount ) over ( partition by transactions.account_id order by transactions.year, transactions.month_number) as credit_amount_running_total,
			sum ( transactions.debit_amount - transactions.credit_amount) over ( partition by transactions.account_id order by transactions.year, transactions.month_number) as balance
		from
			( select
				account_id, 
				date_part( 'year', gl_date ) as year, 
				date_part( 'month', gl_date ) as month_number, 
				date_trunc( 'month', max( gl_date )) + interval '1 month' - interval '1 day' as month_end_date, 
				sum(debit_amount) as debit_amount, 
				sum(credit_amount) as credit_amount
			from
				monthly_summary
			group by
				account_id, date_part( 'year', gl_date ), date_part( 'month', gl_date ) 
				) transactions
		order by
			transactions.account_id,
			transactions.year,
			transactions.month_number;

 return;


end;

 $$ language plpgsql;