drop view if exists fact.account_movement;

create or replace view fact.account_movement
AS
select asm.account_id, asm.year, asm.month_number, asm.month_end_date, asm.debit_amount, asm.credit_amount, 
	asm.debit_amount-asm.credit_amount as movement, 
	(asm.debit_amount-asm.credit_amount - asm.debit_amount_last_month - asm.credit_amount_last_month) AS difference_from_last_month,
	lag(asm.debit_amount-asm.credit_amount, 1) over (order by account_id, year, month_number) as movement_last_month,
	lag(asm.debit_amount-asm.credit_amount,12) over (order by account_id, year, month_number) as movement_last_year
from fact.account_summary_by_month asm
order by asm.account_id, asm.year, asm.month_number;
