drop function if exists books.insert_journal_entry_basic;

create or replace function books.insert_journal_entry_basic (
s_debit_account varchar(50),
n_debit_amount numeric(16,2),
s_credit_account varchar(50),
n_credit_amount numeric(16,2),
d_gl_date date,
s_memo varchar(256)) 
returns int as $$ 
begin

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