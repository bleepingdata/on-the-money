drop function if exists books.insert_gl_entry_basic;

create or replace function books.insert_gl_entry_basic (n_gl_type_id int2, 
n_debit_account_id int,
n_debit_amount numeric(16,2),
n_credit_account_id int,
n_credit_amount numeric(16,2),
d_gl_date date,
s_memo varchar(256),
n_bank_account_id int4,
n_bank_account_is_debit boolean,
n_bank_transaction_id int8) 
returns int as $$ 
declare n_gl_grouping_id int8;
begin

	select
	nextval('books.gl_grouping_seq') into
		n_gl_grouping_id;


	if (n_debit_account_id is null or n_credit_account_id is null)
	then
		RAISE EXCEPTION 'Missing n_debit_account_id or n_credit_account_id'
    	USING HINT = 'Please check your parameters';
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
		bank_account_id,
		bank_transaction_id)
	values ( n_gl_type_id,
 	d_gl_date,
	n_gl_grouping_id,
	n_debit_account_id,
	n_debit_amount,
	0,
	s_memo,
	case when n_bank_account_is_debit = true then n_bank_account_id else null end,
	n_bank_transaction_id);
	
	insert into
		books.general_ledger ( gl_type_id,
		gl_date,
		gl_grouping_id,
		account_id,
		debit_amount,
		credit_amount,
		memo,
		bank_account_id,
		bank_transaction_id)
	values ( n_gl_type_id,
	 d_gl_date,
	n_gl_grouping_id,
	n_credit_account_id,
	0,
	n_credit_amount,
	s_memo,
	case when n_bank_account_is_debit = false then n_bank_account_id else null end,
	n_bank_transaction_id);
	
	return 1;
end;

$$ language plpgsql;