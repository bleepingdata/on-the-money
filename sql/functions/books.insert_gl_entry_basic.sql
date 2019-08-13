drop function if exists books.insert_gl_entry_basic;

create or replace function books.insert_gl_entry_basic (n_gl_type_id int2, 
n_debit_account_id int,
n_debit_amount numeric(16,2),
n_credit_account_id int,
n_credit_amount numeric(16,2),
d_gl_date date,
n_debit_account_id_2 int DEFAULT null,
n_debit_amount_2 numeric(16,2) DEFAULT null,
n_credit_account_id_2 int DEFAULT null,
n_credit_amount_2 numeric(16,2) DEFAULT null,
s_memo varchar(256) DEFAULT null,
n_bank_account_id int4 DEFAULT null,
b_bank_account_is_debit boolean DEFAULT null,
n_bank_transaction_id int8 DEFAULT null,
n_matched_import_rule_id int4 DEFAULT null) 
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
    
    IF ((n_debit_amount + coalesce(n_debit_amount_2,0)) <> (n_credit_amount + coalesce(n_credit_amount_2,0)))
    THEN
	    RAISE EXCEPTION 'Sum of credits does not equal sum of debits'
    	USING HINT = 'Please check your parameters';
    END IF;
   
    IF ((n_debit_account_id_2 IS NOT NULL AND n_debit_amount_2 IS NULL) 
    	OR (n_debit_account_id_2 IS NULL AND n_debit_amount_2 IS NOT NULL))
    THEN
    	RAISE EXCEPTION 'Missing parameter for debit account 2 or debit amount 2'
    	USING HINT = 'Please check your parameters';
    END IF;
    IF ((n_credit_account_id_2 IS NOT NULL AND n_credit_amount_2 IS NULL) 
    	OR (n_credit_account_id_2 IS NULL AND n_credit_amount_2 IS NOT NULL))
    THEN
    	RAISE EXCEPTION 'Missing parameter for credit account 2 or credit amount 2'
    	USING HINT = 'Please check your parameters';
    END IF;
    
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
		bank_transaction_id,
		matched_import_rule_id)
	values ( n_gl_type_id,
 	d_gl_date,
	n_gl_grouping_id,
	n_debit_account_id,
	n_debit_amount,
	0,
	s_memo,
	case when b_bank_account_is_debit = true then n_bank_account_id else null end,
	n_bank_transaction_id,
    n_matched_import_rule_id);
	
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
	case when b_bank_account_is_debit = false then n_bank_account_id else null end,
	n_bank_transaction_id);
	
    IF (n_debit_account_id_2 IS NOT NULL AND n_debit_amount_2 IS NOT NULL)
    THEN
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
			bank_transaction_id,
			matched_import_rule_id)
		values ( n_gl_type_id,
	 	d_gl_date,
		n_gl_grouping_id,
		n_debit_account_id_2,
		n_debit_amount_2,
		0,
		s_memo,
		case when b_bank_account_is_debit = true then n_bank_account_id else null end,
		n_bank_transaction_id,
	    n_matched_import_rule_id);
    END IF;
   
    
	IF (n_credit_account_id_2 IS NOT NULL AND n_credit_amount_2 IS NOT NULL)
    THEN
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
		n_credit_account_id_2,
		0,
		n_credit_amount_2,
		s_memo,
		case when b_bank_account_is_debit = false then n_bank_account_id else null end,
		n_bank_transaction_id);    
    END IF;
    
    return 1;
end;

$$ language plpgsql;