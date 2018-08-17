create or replace function books.insert_transaction_import_rule
	(s_from_account varchar(50),
	s_to_account varchar(50),
	s_type varchar(50),
	s_details varchar(50),
	s_particulars varchar(50),
	s_code varchar(50),
	s_reference varchar(50))
returns int as $$
declare n_from_accountid int;
n_to_accountid int;
n_transactionimportrulesid int;
begin

	select accountid into n_from_accountid from books.account where description = s_from_account;
	select accountid into n_to_accountid from books.account where description = s_to_account;

	if n_from_accountid is null or n_to_accountid is null
	then 
		raise exception 'unable to insert transaction import rule because either fromaccount %s or toaccount %s cannot be found', s_from_account, s_to_account;
		return 0;
	end if;

	insert into books.transactionimportrules (fromaccountid, toaccountid, type, details, particulars, code, reference)
		values (n_from_accountid, n_to_accountid, s_type, s_details, s_particulars, s_code, s_reference)
	 RETURNING transactionimportrulesid into n_transactionimportrulesid;
	
	return n_transactionimportrulesid;
end;
$$ language plpgsql;