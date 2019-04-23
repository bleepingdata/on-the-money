create or replace function books.insert_gl_entry_from_bank_transaction (
n_bank_transaction_id int4 
)
returns int as $$
declare s_debit_account_id int;
s_debit_amount numeric(16,2);
s_credit_account_id varchar(50);
s_credit_amount numeric(16,2);
d_gl_date date;
s_memo varchar(256);
begin


	select s_debit_account_id = case when t.amount < 0 then a.account_id else 0 end,
	  s_debit_amount = case when t.amount < 0 then t.amount else 0 end,
	  s_credit_account_id = case when t.amount >= 0 then a.account_id else 0 end,
	  s_credit_amount = case when t.amount >=0 then t.amount else 0 end,
	  d_gl_date = bank_transaction_date,
	  s_memo = 'imported'
	from books.bank_transaction t
		inner join books.account a on 
			(t.bank_account_friendly_name = a.external_friendly_name
			  and t.bank_account_number = a.external_unique_number)
	where bank_transaction_id = n_bank_transaction_id;

	perform books.insert_gl_entry_basic(1::int2, -- JE 
		s_debit_account::varchar, 
		n_debit_amount::numeric(16,2), 
		s_credit_account::varchar, 
		n_credit_amount::numeric(16,2), 
		d_gl_date::date, 
		s_memo::varchar,
		null::int4);
	
	return 1;
end;

$$ language plpgsql;