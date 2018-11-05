create or replace view fact.uncategorised_transactions
AS
select ?
from fact.account_summary_by_month asm
	inner join books.account a on asm.accountid = a.accountid
	inner join books.accounttype a_t on a.accounttypeid = a_t.accounttypeid
order by asm.accountid, asm.year, asm.month;