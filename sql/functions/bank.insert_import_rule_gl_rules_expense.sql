DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_expense;

-- ============================================================
-- Function : bank.insert_import_rule_gl_rules_expense(varchar, varchar,
--              int2, varchar, boolean, varchar, varchar, varchar, varchar,
--              varchar, varchar, varchar, varchar, varchar)
-- ============================================================
-- Purpose  : Creates a complete expense import rule, including the rule header,
--            matching criteria, and a GL matrix entry that debits the expense
--            account and credits the cash account.
--
-- Parameters
--   s_expense_account                  (varchar) : GL description of the expense account to debit.
--   s_cash_account                     (varchar) : GL description of the cash account to credit.
--   n_priority                         (int2)    : Rule priority. Defaults to 0.
--   s_bank_account                     (varchar) : Bank account description filter.
--   b_is_deposit                       (boolean) : Deposit/withdrawal filter. Defaults to FALSE.
--   s_type                             (varchar) : Transaction type filter.
--   s_other_party_bank_account_number  (varchar) : Other party account number filter.
--   s_details                          (varchar) : Details pattern filter.
--   s_particulars                      (varchar) : Particulars pattern filter.
--   s_code                             (varchar) : Code pattern filter.
--   s_reference                        (varchar) : Reference pattern filter.
--   s_ofx_name                         (varchar) : OFX name pattern filter.
--   s_ofx_memo                         (varchar) : OFX memo pattern filter.
--   s_wildcard_field                   (varchar) : Wildcard pattern matched across all text fields.
--
-- Returns  : void — no return value.
--
-- Usage
--   PERFORM bank.insert_import_rule_gl_rules_expense(
--       s_expense_account := 'Groceries',
--       s_cash_account    := 'ANZ Cheque',
--       s_details         := '%COUNTDOWN%'
--   );
--
-- Dependencies
--   Tables    : books.account, bank.import_rule_gl_matrix
--   Functions : bank.insert_import_rule, bank.insert_import_rule_fields_to_match
-- ============================================================
CREATE OR REPLACE FUNCTION bank.insert_import_rule_gl_rules_expense
	(s_expense_account varchar(50),
	s_cash_account varchar(50),
	n_priority smallint DEFAULT 0,
	s_bank_account varchar(50) DEFAULT NULL,
	b_is_deposit boolean DEFAULT FALSE,
	s_type varchar(50) DEFAULT NULL,
	s_other_party_bank_account_number varchar(56) DEFAULT NULL,
	s_details varchar(50) DEFAULT NULL,
	s_particulars varchar(50) DEFAULT NULL,
	s_code varchar(50) DEFAULT NULL,
	s_reference varchar(50) DEFAULT NULL,
    s_ofx_name varchar(50) DEFAULT NULL,
	s_ofx_memo varchar(255) DEFAULT NULL,
	s_wildcard_field varchar(50) DEFAULT NULL
	)
RETURNS void AS $$
DECLARE n_import_rule_type_id int2;
n_cash_account_id int4;
n_expense_account_id int4;
n_import_rule_id int;
BEGIN
   
    SELECT account_id INTO n_cash_account_id FROM books.account WHERE description = s_cash_account;
	SELECT account_id INTO n_expense_account_id FROM books.account WHERE description = s_expense_account;
   
	IF (n_cash_account_id IS NULL OR n_expense_account_id IS NULL)
	THEN 
		RAISE EXCEPTION 'unable to insert import rule because cash account %s or expense account %s cannot be found', s_cash_account, s_expense_account;
		RETURN;
	END IF;

	SELECT bank.insert_import_rule(s_import_rule_type:='expense', n_priority:=n_priority) INTO n_import_rule_id;

	IF n_import_rule_id IS NULL
	THEN 
		RAISE EXCEPTION 'Unable to add row to bank.import_rule for some reason';
		RETURN;
	END IF;

	PERFORM bank.insert_import_rule_fields_to_match(
		n_import_rule_id:=n_import_rule_id, 
		s_bank_account:=s_bank_account,
		b_is_deposit:=b_is_deposit,
		s_type:=s_type, 
		s_other_party_bank_account_number:=s_other_party_bank_account_number, 
		s_details:=s_details, 
		s_particulars:=s_particulars, 
		s_code:=s_code,
		s_reference:=s_reference,
		s_ofx_name:=s_ofx_name, 
		s_ofx_memo:=s_ofx_memo,
		s_wildcard_field:=s_wildcard_field);

	INSERT INTO bank.import_rule_gl_matrix (import_rule_id, debit_account_id_1, credit_account_id_1)
		VALUES (n_import_rule_id, 
				n_expense_account_id,
				n_cash_account_id
				);
			
	RETURN;
END;
$$ LANGUAGE plpgsql;