create or replace view fact.uncategorised_transactions
AS
select t.transactionid, a_source.description as source_account, tl.depositamount, tl.withdrawalamount, t.banktransactiondate, t.bankprocesseddate, t."type", reference, t.code, t.particulars, t.details
from books."transaction" t 
	inner join books.transactionline tl on t.transactionid = tl.transactionid
	inner join books.account a_source on t.sourceaccountid = a_source.accountid
where t.sourceaccountid <> tl.accountid
and tl.accountid=0;