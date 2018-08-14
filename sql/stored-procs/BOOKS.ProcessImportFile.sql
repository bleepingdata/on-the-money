create or replace function books.processimportfile (sbankaccountnumber varchar(56) = null, 
		sbankaccountdescription varchar(50) = null,
		bremoveoverlappingtransactions boolean = false /* remove txs from same account for the same date(s) */
		)
returns void as $$
declare 
	nbankaccountid int;
	nimportseq int;
begin
-- process a bank file from anz. the file contents must already exist in books.loadimportfile table. parameters determine which account the
-- transactions will be recorded against

--	if @bankaccountnumber is null and @bankaccountdescription is null
--	begin
--		raiserror('all parameters for proc are null or missing', 15,1);
--	end

	-- get the bank account id
	select accountid 
	into nbankaccountid
		from books.account 
		where bankaccountnumber = coalesce(sbankaccountnumber, bankaccountnumber) 
			and description = coalesce(sbankaccountdescription, description)
			and (sbankaccountnumber is not null or sbankaccountdescription is not null);
--	if bankaccountid is null then 
--		raiserror('unable to find books.account entry for bank account %s, description %s', 15,1, @bankaccountnumber, @bankaccountdescription);
--	end if;

	select nextval('books.importseq')
	into nimportseq;
	
	-- add to staging tables
	insert into books.transactionstaging (banktransactiondate, bankprocesseddate, transactionxml, amount, importseq, type, details, particulars, code, reference)
		select
			cast("transaction date" as date), 
			cast ("processed date" as date),
			'<xml>blah</xml>',
			cast(a."amount" as money),--books.cleanstringmoney(a.amount),
			nimportseq,
			"type",
			"details",
			"particulars",
			"code",
			"reference"
		from books.loadimportfile a;

	insert into books.transactionlinestaging (transactionstagingid, accountid, depositamount, withdrawalamount)
		select transactionstagingid, 
				case when amount >= 0.0 then nbankaccountid else 0 end as accountid,
				abs("amount") as depositamount,
				0.0 as withdrawalamount
			from books.transactionstaging 
			where importseq = nimportseq
		union all
		select transactionstagingid, 
				case when amount < 0.0 then nbankaccountid else 0 end as accountid,
				0.0 as depositamount,
				abs(amount) as withdrawalamount
			from books.transactionstaging 
			where importseq = nimportseq
			order by transactionstagingid asc;
--
--	if bremoveoverlappingtransactions == true
--	begin
--		declare @transactionidstodelete table (transactionid bigint primary key clustered);
--
--		insert @transactionidstodelete (transactionid) 
--		select distinct t.transactionid
--			from books.transaction t
--				inner join books.transactionline tl on t.transactionid = tl.transactionid
--				where tl.accountid = @bankaccountid and t.banktransactiondate 
--					in (select banktransactiondate 
--							from books.transactionstaging 
--							where importuniqueidentifier = @importuniqueidentifier);
--
--		delete books.transactionline where transactionid in (select transactionid from @transactionidstodelete);
--		delete books.transaction where transactionid in (select transactionid from @transactionidstodelete);
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
--			from books.transactionstaging ts
--			inner join books.transactionlinestaging tls on ts.transactionstagingid = tls.transactionstagingid
--		intersect 
--		select t.banktransactiondate, t.bankprocesseddate, tl.depositamount, tl.withdrawalamount, tl.accountid
--			from books.transaction t
--			inner join books.transactionline tl on t.transactionid = tl.transactionid
--		) dupes
--
--		if @dupes > @max_allowable_dupes
--		begin
--			raiserror('unable to import transactions because %i duplicates were found in books.transactionlinestaging', 15, 1, @dupes) with nowait;
--			return 1;
--		end
--	end

	-- import into transaction tables
	insert into books.transaction (banktransactiondate, bankprocesseddate, transactionxml, amount, importseq, type, details, particulars, code, reference)
	select 
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
		from books.transactionstaging a;

	insert into books.transactionline (transactionid, accountid, depositamount, withdrawalamount)
		select transactionid, 
			case when amount >= 0.0 then nbankaccountid else 0 end as accountid,
			abs(amount) as depositamount,
			0.0 as withdrawalamount
			from books.transaction 
			where importseq = nimportseq
		union all
		select transactionid, 
			case when amount < 0.0 then nbankaccountid else 0 end as accountid,
			0.0 as depositamount,
			abs(amount) as withdrawalamount
			from books.transaction 
			where importseq = nimportseq
			order by transactionid asc;


end;
$$ language plpgsql;