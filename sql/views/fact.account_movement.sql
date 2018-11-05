create or replace view fact.account_movement
AS
select asm.accountid, a.description, a_t.description as account_type, year, asm.month, asm.month_as_date, (asm.deposit_amount - asm.withdrawal_amount) as movement
from fact.account_summary_by_month asm
	inner join books.account a on asm.accountid = a.accountid
	inner join books.accounttype a_t on a.accounttypeid = a_t.accounttypeid
order by asm.accountid, asm.year, asm.month;