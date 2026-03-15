create or replace function books.insert_manual_entry
	(s_from_account varchar(50),
	s_to_account varchar(50),
	d_bank_transaction_date date,
	d_bank_processed_date date,
	n_amount numeric(16,2),
	s_type varchar(50),
	s_details varchar(50),
	s_particulars varchar(50),
	s_code varchar(50),
	s_reference varchar(50))
returns int as $$
declare n_from_accountid int;
n_to_accountid int;
n_transactionstagingid int8;
begin

	select accountid into n_from_accountid from books.account where description = s_from_account;
	select accountid into n_to_accountid from books.account where description = s_to_account;

    delete from books.transactionlinestaging;
    delete from books.transactionstaging;
   
	if n_from_accountid is null or n_to_accountid is null
	then 
		raise exception 'unable to insert manual transaction because either fromaccount %s or toaccount %s cannot be found', s_from_account, s_to_account;
		return 0;
	end if;

	insert into books.transactionstaging (sourceaccountid, 
				banktransactiondate, 
				bankprocesseddate, 
				transactionxml, 
				amount, 
				type, 
				details, 
				particulars, 
				code, 
				reference,
				importseq,
				importdatetime)
		values (n_from_accountid, 
			d_bank_transaction_date, 
			d_bank_processed_date, 
			'', 
			n_amount, s_type, s_details, s_particulars, s_code, s_reference,
			1,
			now())
	 RETURNING transactionstagingid into n_transactionstagingid;
	

	
	return n_transactionstagingid;
end;
$$ language plpgsql;