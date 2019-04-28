drop view if exists fact.account_balance;

create or replace view fact.account_balance
AS
select asm.account_id, year, asm.month_number, asm.month_end_date, asm.balance
from fact.account_summary_by_month asm
order by asm.account_id, asm.year, asm.month_number;