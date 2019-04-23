create or replace function books.insert_gl_entry_basic (n_gl_type_id int2, s_debit_account varchar(50),
n_debit_amount numeric(16,2),
s_credit_account varchar(50),
n_credit_amount numeric(16,2),
d_gl_date date,
s_memo varchar(256),
n_source_identifier int8) 
returns int as $$ 
declare n_debit_account_id int;
n_credit_account_id int;
n_gl_grouping_id int8;
begin

	select
	nextval('books.gl_grouping_seq') into
		n_gl_grouping_id;

	select
	accountid into
		n_debit_account_id
	from
		books.account
	where
		description = s_debit_account;

	select
	accountid into
		n_credit_account_id
	from
		books.account
	where
		description = s_credit_account;

	if n_debit_account_id is null or n_credit_account_id is null 
		then raise exception 'unable to insert journal entry because either fromaccount %s or toaccount %s cannot be found',s_from_account,s_to_account;
		return 0;
	end if;

	insert
	into
		books.general_ledger ( gl_type_id,
		gl_date,
		gl_grouping_id,
		account_id,
		debit_amount,
		credit_amount,
		memo,
		source_identifier)
	values ( n_gl_type_id,
 	d_gl_date,
	n_gl_grouping_id,
	n_debit_account_id,
	n_debit_amount,
	0,
	s_memo,
	n_source_identifier);
	
	insert into
		books.general_ledger ( gl_type_id,
		gl_date,
		gl_grouping_id,
		account_id,
		debit_amount,
		credit_amount,
		memo,
		source_identifier)
	values ( n_gl_type_id,
	 d_gl_date,
	n_gl_grouping_id,
	n_credit_account_id,
	0,
	n_credit_amount,
	s_memo,
	n_source_identifier);
	
	return 1;
end;

$$ language plpgsql;