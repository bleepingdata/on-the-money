DROP FUNCTION IF EXISTS books.insert_gl_entry_from_bank_transaction;

-- ============================================================
-- Function : books.insert_gl_entry_from_bank_transaction(int8)
-- ============================================================
-- Purpose  : Resolves GL debit/credit accounts for a bank transaction using
--            its matched import rule, deletes any existing GL entries for that
--            transaction, and posts a new double-entry GL record via
--            books.insert_gl_entry_basic. Falls back to uncategorised accounts
--            when no import rule is matched.
--
-- Parameters
--   n_transaction_id  (int8) : The bank transaction ID to post to the GL.
--
-- Returns  : int — always returns 1 on success.
--
-- Usage
--   PERFORM books.insert_gl_entry_from_bank_transaction(12345);
--
-- Dependencies
--   Tables    : bank.transaction, bank.import_rule, bank.import_rule_gl_matrix,
--               bank.bank_account_gl_account_link, books.general_ledger,
--               books.account
--   Functions : books.insert_gl_entry_basic
-- ============================================================
CREATE OR REPLACE FUNCTION books.insert_gl_entry_from_bank_transaction (
n_transaction_id int8 
)
RETURNS int AS $$
DECLARE n_import_rule_type_id int2;
n_amount numeric(16,2);
n_debit_account_id int;
n_debit_account_balance numeric(16,2);
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
BEGIN

	SELECT INTO n_import_rule_type_id
		ir.import_rule_type_id
		FROM bank.transaction t
			LEFT JOIN bank.import_rule ir ON t.matched_import_rule_id = ir.import_rule_id
		WHERE t.transaction_id=n_transaction_id;
	
	DELETE FROM books.general_ledger WHERE bank_transaction_id = n_transaction_id;

	IF (n_import_rule_type_id IS NULL)
	THEN
		n_import_rule_type_id = 1; /* Standard */
	END IF;

	SELECT 
		INTO n_debit_account_id, n_debit_amount, n_credit_account_id, n_credit_amount, d_gl_date, 
		n_bank_account_id, b_bank_account_is_debit, n_matched_import_rule_id, s_memo
		COALESCE(irg.debit_account_id_1,(SELECT account_id FROM books.account WHERE description='uncategorised debit')),
		ABS(t.amount),
		COALESCE(irg.credit_account_id_1,(SELECT account_id FROM books.account WHERE description='uncategorised credit')),
		ABS(t.amount),
		t.processed_date,
		t.bank_account_id,
		CASE WHEN t.amount > 0 
		    THEN TRUE
		    ELSE FALSE END, -- b_bank_account_is_debit
		t.matched_import_rule_id,
		'imported'
	FROM bank.transaction t
		LEFT JOIN bank.import_rule ir ON t.matched_import_rule_id = ir.import_rule_id
		LEFT JOIN bank.import_rule_gl_matrix irg ON ir.import_rule_id = irg.import_rule_id
	    LEFT JOIN bank.bank_account_gl_account_link b_g ON t.bank_account_id = b_g.bank_account_id AND b_g.is_default=TRUE
	WHERE t.transaction_id = n_transaction_id;


	PERFORM books.insert_gl_entry_basic(n_gl_type_id:=1::int2, -- JE 
		n_debit_account_id:=n_debit_account_id::int4, 
		n_debit_amount:=n_debit_amount::numeric(16,2), 
		n_credit_account_id:=n_credit_account_id::int4, 
		n_credit_amount:=n_credit_amount::numeric(16,2), 
		n_debit_account_id_2:=n_debit_account_id_2::int4, 
		n_debit_amount_2:=n_debit_amount_2::numeric(16,2), 
		n_credit_account_id_2:=n_credit_account_id_2::int4, 
		n_credit_amount_2:=n_credit_amount_2::numeric(16,2), 
		d_gl_date:=d_gl_date::date, 
		s_memo:=s_memo::varchar,
		n_bank_account_id:=n_bank_account_id::int4,
		b_bank_account_is_debit:=b_bank_account_is_debit::boolean,
		n_bank_transaction_id:=n_transaction_id::int8,
	    n_matched_import_rule_id:=n_matched_import_rule_id::int4);
	
	RETURN 1;
END;

$$ LANGUAGE plpgsql;