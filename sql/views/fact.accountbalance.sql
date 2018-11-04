create or replace view fact.account_balance
AS
select asm.accountid, a.description, asm.year, asm.month, asm.month_as_date, asm.balance
from fact.account_summary_by_month asm
	inner join books.account a on asm.accountid = a.accountid
order by asm.accountid, asm.year, asm.month;