drop view if exists fact.account_balance;

create or replace view fact.account_balance
AS
select asm.account_id, year, asm.month_number, asm.month_end_date, asm.balance, 
	lag(asm.balance,12) over(partition by asm.account_id order by asm.year, asm.month_number) as balance_last_year
from fact_tbl.account_summary_by_month asm
where asm.balance <> 0
order by asm.account_id, asm.year, asm.month_number;