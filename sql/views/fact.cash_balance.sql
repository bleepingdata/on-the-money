drop view if exists fact.cash_balance;

create or replace view fact.cash_balance
as
select sum(asm.balance) as "balance", asm."year", asm.month_number, asm.month_end_date
	from books.account a
		inner join books.account_type a_t on a.account_type_id = a_t.account_type_id
		inner join fact_tbl.account_summary_by_month asm on a.account_id = asm.account_id
 	where a.description = 'Cash'
  	group by asm."year", asm.month_number, asm.month_end_date;