create OR replace function books.processimportfile_excel_anzmortgage @bankaccountnumber nvarchar(56) = null, 
		@bankaccountdescription nvarchar(50) = null,
		@removeoverlappingtransactions bit = 0 /* remove txs from same account for the same date(s) */
as
begin
-- process a bank mortgage export from anz. the file contents must already exist in books.loadimportfile_excel_anzmortgage table. parameters determine which account the
-- transactions will be recorded against


	if @bankaccountnumber is null and @bankaccountdescription is null
	begin
		raiserror('all parameters for proc are null or missing', 15,1);
	end

	-- get the bank account id
	declare @bankaccountid int = (select accountid 
									from books.account 
									where bankaccountnumber = isnull(@bankaccountnumber, bankaccountnumber) 
										and description = isnull(@bankaccountdescription, description)
										and (@bankaccountnumber is not null or @bankaccountdescription is not null));
	if @bankaccountid is null
	begin
		raiserror('unable to find books.account entry for bank account %s, description %s', 15,1, @bankaccountnumber, @bankaccountdescription);
	end

	declare @importuniqueidentifier uniqueidentifier = newid();

	-- add to staging tables
	insert books.[transactionstaging] (banktransactiondate, bankprocesseddate, transactionxml, amount, importuniqueidentifier, [details])
		select 
			try_convert(date, [date]) as [banktransactiondate], try_convert(date, [date]) as [bankprocesseddate],
			(select [id]
					  ,[date]
					  ,[details]
					  ,[amount]
					  ,[balance]
				  from [books].[loadimportfile_excel_anzmortgage] b
				  where b.id = a.id
				  for xml path ('row'), type
				  ) 
				as [transactionxml],
			books.cleanstringmoney([amount]) as [amount],
			@importuniqueidentifier,
			[details]
		from [books].[loadimportfile_excel_anzmortgage] a

	insert [books].transactionlinestaging (transactionstagingid, accountid, depositamount, withdrawalamount)
		select transactionstagingid, 
				case when amount >= 0 then @bankaccountid else 0 end as [accountid],
				abs(amount) as [depositamount],
				0 as withdrawalamount
			from books.[transactionstaging] 
			where importuniqueidentifier = @importuniqueidentifier
		union all
		select transactionstagingid, 
				case when amount < 0 then @bankaccountid else 0 end as [accountid],
				0 as depositamount,
				abs(amount) as [withdrawalamount]
			from books.[transactionstaging] 
			where importuniqueidentifier = @importuniqueidentifier
			order by transactionstagingid asc;

	if @removeoverlappingtransactions = 1
	begin
		declare @transactionidstodelete table (transactionid bigint primary key clustered);

		insert @transactionidstodelete (transactionid) 
		select distinct t.transactionid
			from books.[transaction] t
				inner join books.transactionline tl on t.transactionid = tl.transactionid
				where tl.accountid = @bankaccountid and t.banktransactiondate 
					in (select banktransactiondate 
							from books.transactionstaging 
							where importuniqueidentifier = @importuniqueidentifier);

		delete books.transactionline where transactionid in (select transactionid from @transactionidstodelete);
		delete books.[transaction] where transactionid in (select transactionid from @transactionidstodelete);
	end
	else
	begin
		-- check staging tables (are we duplicating transactions, etc)
		declare @max_allowable_dupes int = 0, @dupes int = 0;

		
		select @dupes = count(*) from
		(
		select ts.banktransactiondate, ts.bankprocesseddate, tls.depositamount, tls.withdrawalamount, tls.accountid
			from books.[transactionstaging] ts
			inner join books.[transactionlinestaging] tls on ts.transactionstagingid = tls.transactionstagingid
		intersect 
		select t.banktransactiondate, t.bankprocesseddate, tl.depositamount, tl.withdrawalamount, tl.accountid
			from books.[transaction] t
			inner join books.[transactionline] tl on t.transactionid = tl.transactionid
		) dupes

		if @dupes > @max_allowable_dupes
		begin
			raiserror('unable to import transactions because %i duplicates were found in books.[transactionlinestaging]', 15, 1, @dupes) with nowait;
			return 1;
		end
	end

	-- import into transaction tables
	insert books.[transaction] (banktransactiondate, bankprocesseddate, transactionxml, amount, importuniqueidentifier, [type], [details], [particulars], [code], [reference])
	select 
		[banktransactiondate], 
		[bankprocesseddate],
		[transactionxml],
		[amount],
		importuniqueidentifier,
		[type],
		[details],
		[particulars],
		[code],
		[reference]
		from [books].[transactionstaging] a

	insert [books].transactionline (transactionid, accountid, depositamount, withdrawalamount)
		select transactionid, 
			case when amount >= 0 then @bankaccountid else 0 end as [accountid],
			abs(amount) as [depositamount],
			0 as withdrawalamount
			from books.[transaction] 
			where importuniqueidentifier = @importuniqueidentifier
		union all
		select transactionid, 
			case when amount < 0 then @bankaccountid else 0 end as [accountid],
			0 as depositamount,
			abs(amount) as [withdrawalamount]
			from books.[transaction] 
			where importuniqueidentifier = @importuniqueidentifier
			order by transactionid asc;


END;