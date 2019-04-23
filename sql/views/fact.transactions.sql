drop view fact.transactions;

create or replace view fact.transactions
AS
select t.transactionid, a_source.description as debit_account, sum(tl_source.depositamount+tl_dest.depositamount) as debit_amount, 
	a_dest.description as credit_account, SUM(tl_source.withdrawalamount+tl_dest.withdrawalamount) as credit_amount, 
	t.banktransactiondate, 
	t.bankprocesseddate, 
	t."type", 
	t.reference, 
	t.code, 
	t.particulars, 
	t.details
from books."transaction" t 
	left join books.transactionline tl_source on t.transactionid = tl_source.transactionid and t.sourceaccountid=tl_source.accountid
	left join books.transactionline tl_dest on t.transactionid = tl_dest.transactionid and t.sourceaccountid <> tl_dest.accountid
	left join books.account a_source on tl_source.accountid = a_source.accountid
	left join books.account a_dest on tl_dest.accountid = a_dest.accountid
group by t.transactionid, a_source.description, a_dest.description, t.banktransactiondate, t.bankprocesseddate, t.type, t.reference, t.code, t.particulars, t.details
;
