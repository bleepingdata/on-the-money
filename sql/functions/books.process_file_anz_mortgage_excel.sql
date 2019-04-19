drop
	function if exists books.processimportfile_excel_anzmortgage;

 create or replace function books.processimportfile_excel_anzmortgage ( sbankaccountnumber varchar( 56 ) = null, sbankaccountdescription varchar( 50 ) = null, bremoveoverlappingtransactions boolean = false /* remove txs from same account for the same date(s) */
) returns void as $$ declare nbankaccountid int;

 nimportseq int;
 
begin

-- process a bank file from anz. the file contents must already exist in books.loadimportfile_excel_anzmortgage table. parameters determine which account the
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
		books.transactionstaging ( sourceaccountid, banktransactiondate, bankprocesseddate, transactionxml, amount, importseq, details) select
			nbankaccountid,
			cast( a."Date" as date ),
			cast ( a."Date" as date ),
			'<xml>blah</xml>',
			cast( a."Amount" as money ),
			nimportseq,
			"Details"
		from
			books.loadimportfile_excel_anzmortgage a;

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
	and coalesce( ts.details, '' ) = coalesce( t.details, '' );


 delete
from
	books.transaction t
		using books.transactionstaging ts
where
	t.sourceaccountid=nbankaccountid
	and ts.banktransactiondate = t.banktransactiondate
	and ts.amount = t.amount
	and coalesce( ts.details, '' ) = coalesce( t.details, '' );


end if;
-- import into transaction tables
 insert
	into
		books.transaction ( sourceaccountid, banktransactiondate, bankprocesseddate, transactionxml, amount, importseq, details ) select
			nbankaccountid,
			banktransactiondate,
			bankprocesseddate,
			transactionxml,
			amount,
			importseq,
			details
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
-- 
--	declare @importuniqueidentifier uniqueidentifier = newid();
--
--	-- add to staging tables
--	insert books.[transactionstaging] (banktransactiondate, bankprocesseddate, transactionxml, amount, importuniqueidentifier, [details])
--		select 
--			try_convert(date, [date]) as [banktransactiondate], try_convert(date, [date]) as [bankprocesseddate],
--			(select [id]
--					  ,[date]
--					  ,[details]
--					  ,[amount]
--					  ,[balance]
--				  from [books].[loadimportfile_excel_anzmortgage] b
--				  where b.id = a.id
--				  for xml path ('row'), type
--				  ) 
--				as [transactionxml],
--			books.cleanstringmoney([amount]) as [amount],
--			@importuniqueidentifier,
--			[details]
--		from [books].[loadimportfile_excel_anzmortgage] a
--
--	insert [books].transactionlinestaging (transactionstagingid, accountid, depositamount, withdrawalamount)
--		select transactionstagingid, 
--				case when amount >= 0 then @bankaccountid else 0 end as [accountid],
--				abs(amount) as [depositamount],
--				0 as withdrawalamount
--			from books.[transactionstaging] 
--			where importuniqueidentifier = @importuniqueidentifier
--		union all
--		select transactionstagingid, 
--				case when amount < 0 then @bankaccountid else 0 end as [accountid],
--				0 as depositamount,
--				abs(amount) as [withdrawalamount]
--			from books.[transactionstaging] 
--			where importuniqueidentifier = @importuniqueidentifier
--			order by transactionstagingid asc;
--
--	if @removeoverlappingtransactions = 1
--	begin
--		declare @transactionidstodelete table (transactionid bigint primary key clustered);
--
--		insert @transactionidstodelete (transactionid) 
--		select distinct t.transactionid
--			from books.[transaction] t
--				inner join books.transactionline tl on t.transactionid = tl.transactionid
--				where tl.accountid = @bankaccountid and t.banktransactiondate 
--					in (select banktransactiondate 
--							from books.transactionstaging 
--							where importuniqueidentifier = @importuniqueidentifier);
--
--		delete books.transactionline where transactionid in (select transactionid from @transactionidstodelete);
--		delete books.[transaction] where transactionid in (select transactionid from @transactionidstodelete);
--	end
--	else
--	begin
--		-- check staging tables (are we duplicating transactions, etc)
--		declare @max_allowable_dupes int = 0, @dupes int = 0;
--
--		
--		select @dupes = count(*) from
--		(
--		select ts.banktransactiondate, ts.bankprocesseddate, tls.depositamount, tls.withdrawalamount, tls.accountid
--			from books.[transactionstaging] ts
--			inner join books.[transactionlinestaging] tls on ts.transactionstagingid = tls.transactionstagingid
--		intersect 
--		select t.banktransactiondate, t.bankprocesseddate, tl.depositamount, tl.withdrawalamount, tl.accountid
--			from books.[transaction] t
--			inner join books.[transactionline] tl on t.transactionid = tl.transactionid
--		) dupes
--
--		if @dupes > @max_allowable_dupes
--		begin
--			raiserror('unable to import transactions because %i duplicates were found in books.[transactionlinestaging]', 15, 1, @dupes) with nowait;
--			return 1;
--		end
--	end
--
--	-- import into transaction tables
--	insert books.[transaction] (banktransactiondate, bankprocesseddate, transactionxml, amount, importuniqueidentifier, [type], [details], [particulars], [code], [reference])
--	select 
--		[banktransactiondate], 
--		[bankprocesseddate],
--		[transactionxml],
--		[amount],
--		importuniqueidentifier,
--		[type],
--		[details],
--		[particulars],
--		[code],
--		[reference]
--		from [books].[transactionstaging] a
--
--	insert [books].transactionline (transactionid, accountid, depositamount, withdrawalamount)
--		select transactionid, 
--			case when amount >= 0 then @bankaccountid else 0 end as [accountid],
--			abs(amount) as [depositamount],
--			0 as withdrawalamount
--			from books.[transaction] 
--			where importuniqueidentifier = @importuniqueidentifier
--		union all
--		select transactionid, 
--			case when amount < 0 then @bankaccountid else 0 end as [accountid],
--			0 as depositamount,
--			abs(amount) as [withdrawalamount]
--			from books.[transaction] 
--			where importuniqueidentifier = @importuniqueidentifier
--			order by transactionid asc;
--
--
--END;