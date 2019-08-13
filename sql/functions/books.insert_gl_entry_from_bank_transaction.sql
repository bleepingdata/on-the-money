drop function if exists books.insert_gl_entry_from_bank_transaction;

create or replace function books.insert_gl_entry_from_bank_transaction (
n_transaction_id int8 
)
returns int as $$
declare n_import_rule_type_id int2;
n_debit_account_id int;
n_debit_amount numeric(16,2);
n_credit_account_id int;
n_credit_amount numeric(16,2);
n_debit_account_id_2 int;
n_debit_amount_2 numeric(16,2);
n_credit_account_id_2 int;
n_credit_amount_2 numeric(16,2);
d_gl_date date;
s_memo varchar(256);
n_bank_account_id int4;
b_bank_account_is_debit boolean;
n_matched_import_rule_id int4;
n_uncategorised_income_account_id int;
n_uncategorised_expense_account_id int;
begin

	select into n_import_rule_type_id
		ir.import_rule_type_id
		from bank.transaction t
			left join bank.import_rule ir on t.matched_import_rule_id = ir.import_rule_id;
	
	if (n_import_rule_type_id is null)
	then
		n_import_rule_type_id = 1; /* Standard */
	end if;

	select into n_uncategorised_income_account_id
		a.account_id
		from books.account a where description ='uncategorised income';
	
	select into n_uncategorised_expense_account_id
		a.account_id
		from books.account a where description ='uncategorised expense';
	
	if (n_import_rule_type_id = 1) /* Standard */
	then
		
		select into n_debit_account_id, n_debit_amount, n_credit_account_id, n_credit_amount, d_gl_date, 
			n_bank_account_id, b_bank_account_is_debit, n_matched_import_rule_id, s_memo
			case when t.amount > 0 
				then COALESCE(ir.account_id, b_g.account_id)
				else 
					case when ir.other_party_account_id is null then n_uncategorised_expense_account_id else ir.other_party_account_id end 
				end,
			ABS(t.amount),
			case when t.amount > 0 
				then case when ir.other_party_account_id is null then n_uncategorised_income_account_id else ir.other_party_account_id end
				else COALESCE(ir.account_id, b_g.account_id) 
				end,
			ABS(t.amount),
			t.processed_date,
			t.bank_account_id,
			case when t.amount > 0 
			    then true
			    else false end, -- b_bank_account_is_debit
			t.matched_import_rule_id,
			'imported'
		from bank.transaction t
			LEFT JOIN bank.import_rule ir ON t.matched_import_rule_id = ir.import_rule_id
		    left JOIN bank.bank_account_gl_account_link b_g ON t.bank_account_id = b_g.bank_account_id AND b_g.is_default=true
		where t.transaction_id = n_transaction_id;

	end if;
	
	if (n_import_rule_type_id = 2) /* Fixed Rate Loan Repayment */
	then
		
	-- TODO replace this logic with logic that splits the transactions
		select into n_debit_account_id, n_debit_amount, n_credit_account_id, n_credit_amount, d_gl_date, 
			n_bank_account_id, b_bank_account_is_debit, n_matched_import_rule_id, s_memo
			case when t.amount > 0 
				then COALESCE(ir.account_id, b_g.account_id)
				else 
					case when ir.other_party_account_id is null then n_uncategorised_expense_account_id else ir.other_party_account_id end 
				end,
			ABS(t.amount),
			case when t.amount > 0 
				then case when ir.other_party_account_id is null then n_uncategorised_income_account_id else ir.other_party_account_id end
				else COALESCE(ir.account_id, b_g.account_id) 
				end,
			ABS(t.amount),
			t.processed_date,
			t.bank_account_id,
			case when t.amount > 0 
			    then true
			    else false end, -- b_bank_account_is_debit
			t.matched_import_rule_id,
			'imported'
		from bank.transaction t
			LEFT JOIN bank.import_rule ir ON t.matched_import_rule_id = ir.import_rule_id
		    left JOIN bank.bank_account_gl_account_link b_g ON t.bank_account_id = b_g.bank_account_id AND b_g.is_default=true
		where t.transaction_id = n_transaction_id;

	end if;

	perform books.insert_gl_entry_basic(n_gl_type_id:=1::int2, -- JE 
		n_debit_account_id:=n_debit_account_id::int, 
		n_debit_amount:=n_debit_amount::numeric(16,2), 
		n_credit_account_id:=n_credit_account_id::int, 
		n_credit_amount:=n_credit_amount::numeric(16,2), 
		n_debit_account_id_2:=n_debit_account_id_2::int, 
		n_debit_amount_2:=n_debit_amount_2::numeric(16,2), 
		n_credit_account_id_2:=n_credit_account_id_2::int, 
		n_credit_amount_2:=n_credit_amount_2::numeric(16,2), 
		d_gl_date:=d_gl_date::date, 
		s_memo:=s_memo::varchar,
		n_bank_account_id:=n_bank_account_id::int4,
		b_bank_account_is_debit:=b_bank_account_is_debit::boolean,
		n_bank_transaction_id:=n_transaction_id::int8,
	    n_matched_import_rule_id:=n_matched_import_rule_id::int4);
	
	return 1;
end;

$$ language plpgsql;