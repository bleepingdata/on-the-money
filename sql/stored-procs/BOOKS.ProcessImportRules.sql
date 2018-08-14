
create or replace function books.processimportrules ()
RETURNS void AS $$
begin
	
	update books.transactionline as to_transaction_lines
	set accountid = from_transaction_lines.toaccountid -- select *
	from 
	(
		select tl.accountid as fromaccountid, tl.transactionid, tir.toaccountid
		from books.transactionline tl
			inner join books.transaction t on tl.transactionid = t.transactionid
			inner join books.transactionimportrules tir on tl.accountid = tir.fromaccountid 
					and tir.appliesfromdate <= t.banktransactiondate 
					and tir.appliesuntildate >= t.banktransactiondate
		where 
			(t.type = tir.type or tir.type is null)
			and (t.details = tir.details or tir.details is null)
			and (t.particulars = tir.particulars or tir.particulars is null)
			and (t.code = tir.code or tir.code is null)
			and (t.reference = tir.reference or tir.reference is null)
		) from_transaction_lines
		WHERE from_transaction_lines.transactionid = to_transaction_lines.transactionid
			and from_transaction_lines.fromaccountid <> to_transaction_lines.accountid;

END;
$$ language plpgsql;