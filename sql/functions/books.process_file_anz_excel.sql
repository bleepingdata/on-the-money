drop
	function if exists books.process_file_anz_excel;

 create
or replace
function books.process_file_anz_excel ( sbankaccountnumber varchar( 56 ) = null, sbankaccountdescription varchar( 50 ) = null, bremoveoverlappingtransactions boolean = false /* remove txs from same account for the same date(s) */
) returns void as $$ declare nbankaccountid int;

 nimportseq int;

 begin
-- process a bank file from anz. the file contents must already exist in books.loadimportfile table. parameters determine which account the
-- transactions will be recorded against
--	if @bankaccountnumber is null and @bankaccountdescription is null
--	begin
--		raiserror('all parameters for proc are null or missing', 15,1);
--	end
-- get the bank account id
 select
	accountid into
		nbankaccountid
	from
		books.account
	where
		( bankaccountnumber = coalesce( sbankaccountnumber, bankaccountnumber )
		and description = coalesce( sbankaccountdescription, description ))
		and ( sbankaccountnumber is not null
		or sbankaccountdescription is not null );

 if nbankaccountid is null then raise exception 'Nonexistent sbankaccountnumber or sbankaccountdescription --> %, %',
sbankaccountnumber,
sbankaccountdescription
	using HINT = 'Please check incoming parameters for sbankaccountnumber and sbankaccountdescription';


end if;

 select
	nextval( 'books.importseq' ) into
		nimportseq;
-- add to staging tables
 insert
	into
		books.transactionstaging ( sourceaccountid, banktransactiondate, bankprocesseddate, transactionxml, amount, importseq, type, details, particulars, code, reference ) select
			nbankaccountid,
			cast( a."Transaction Date" as date ),
			cast ( a."Processed Date" as date ),
			'<xml>blah</xml>',
			cast( a."Amount" as money ),
			--books.cleanstringmoney(a.amount),
 nimportseq,
			"Type",
			"Details",
			"Particulars",
			"Code",
			"Reference"
		from
			books.loadimportfile a;

 insert
	into
		books.transactionlinestaging ( transactionstagingid, accountid, depositamount, withdrawalamount ) select
			transactionstagingid,
			case
				when amount >= 0.0 then nbankaccountid
				else 0
			end as accountid,
			abs( "amount" ) as depositamount,
			0.0 as withdrawalamount
		from
			books.transactionstaging
		where
			importseq = nimportseq
	union all select
			transactionstagingid,
			case
				when amount < 0.0 then nbankaccountid
				else 0
			end as accountid,
			0.0 as depositamount,
			abs( amount ) as withdrawalamount
		from
			books.transactionstaging
		where
			importseq = nimportseq
		order by
			transactionstagingid asc;

 if bremoveoverlappingtransactions then delete
from
	books.transactionline tl
		using books.transactionstaging ts,
	books.transaction t
where
	t.sourceaccountid=nbankaccountid
	and t.transactionid = tl.transactionid
	and ts.banktransactiondate = t.banktransactiondate
	and ts.amount = t.amount
	and coalesce( ts.code, '' ) = coalesce( t.code, '' )
	and coalesce( ts.details, '' ) = coalesce( t.details, '' )
	and coalesce( ts.particulars, '' ) = coalesce( t.particulars, '' )
	and coalesce( ts.reference, '' ) = coalesce( t.reference, '' );


 delete
from
	books.transaction t
		using books.transactionstaging ts
where
	t.sourceaccountid=nbankaccountid
	and ts.banktransactiondate = t.banktransactiondate
	and ts.amount = t.amount
	and coalesce( ts.code, '' ) = coalesce( t.code, '' )
	and coalesce( ts.details, '' ) = coalesce( t.details, '' )
	and coalesce( ts.particulars, '' ) = coalesce( t.particulars, '' )
	and coalesce( ts.reference, '' ) = coalesce( t.reference, '' );


end if;
-- import into transaction tables
 insert
	into
		books.transaction ( sourceaccountid, banktransactiondate, bankprocesseddate, transactionxml, amount, importseq, type, details, particulars, code, reference ) select
			nbankaccountid,
			banktransactiondate,
			bankprocesseddate,
			transactionxml,
			amount,
			importseq,
			type,
			details,
			particulars,
			code,
			reference
		from
			books.transactionstaging a;

 insert
	into
		books.transactionline ( transactionid, accountid, depositamount, withdrawalamount ) select
			transactionid,
			case
				when amount >= 0.0 then nbankaccountid
				else 0
			end as accountid,
			abs( amount ) as depositamount,
			0.0 as withdrawalamount
		from
			books.transaction
		where
			importseq = nimportseq
	union all select
			transactionid,
			case
				when amount < 0.0 then nbankaccountid
				else 0
			end as accountid,
			0.0 as depositamount,
			abs( amount ) as withdrawalamount
		from
			books.transaction
		where
			importseq = nimportseq
		order by
			transactionid asc;


end;

 $$ language plpgsql;