drop function if exists books.insert_gl_entry_from_bank_transaction;

create or replace function books.insert_gl_entry_from_bank_transaction (
n_transaction_id int8 
)
returns int as $$
declare n_debit_account_id int;
n_debit_amount numeric(16,2);
n_credit_account_id int;
n_credit_amount numeric(16,2);
d_gl_date date;
s_memo varchar(256);
n_bank_account_id int4;
n_bank_account_is_debit boolean;
n_matched_import_rule_id int4;
n_uncategorised_income_account_id int;
n_uncategorised_expense_account_id int;
begin

	select into n_uncategorised_income_account_id
		a.account_id
		from books.account a where description ='uncategorised income';
	
	select into n_uncategorised_expense_account_id
		a.account_id
		from books.account a where description ='uncategorised expense';
	
	select into n_debit_account_id, n_debit_amount, n_credit_account_id, n_credit_amount, d_gl_date, 
		n_bank_account_id, n_bank_account_is_debit, n_matched_import_rule_id, s_memo
		case when t.amount > 0 
			then b_g.account_id
			else 
				case when other_party_account_id is null then n_uncategorised_expense_account_id else other_party_account_id end 
			end,
		ABS(t.amount),
		case when t.amount > 0 
			then case when other_party_account_id is null then n_uncategorised_income_account_id else other_party_account_id end
			else b_g.account_id 
			end,
		ABS(t.amount),
		t.processed_date,
		t.bank_account_id,
		case when t.amount > 0 
		    then true
		    else false end, -- n_bank_account_is_debit
		t.matched_import_rule_id,
		'imported'
	from bank.transaction t
	    left JOIN bank.bank_account_gl_account_link b_g ON t.bank_account_id = b_g.bank_account_id AND b_g.is_default=true
	where t.transaction_id = n_transaction_id;

	perform books.insert_gl_entry_basic(1::int2, -- JE 
		n_debit_account_id::int, 
		n_debit_amount::numeric(16,2), 
		n_credit_account_id::int, 
		n_credit_amount::numeric(16,2), 
		d_gl_date::date, 
		s_memo::varchar,
		n_bank_account_id::int4,
		n_bank_account_is_debit::boolean,
		n_transaction_id::int8,
	    n_matched_import_rule_id::int4);
	
	return 1;
end;

$$ language plpgsql;