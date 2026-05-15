DROP FUNCTION IF EXISTS books.insert_journal_entry_basic;

-- ============================================================
-- Function : books.insert_journal_entry_basic(varchar, numeric, varchar,
--              numeric, date, varchar)
-- ============================================================
-- Purpose  : Convenience wrapper around books.insert_gl_entry_basic that
--            accepts account description strings instead of integer account
--            IDs for posting a simple two-sided journal entry.
--
-- Parameters
--   s_debit_account   (varchar) : Description of the debit account.
--   n_debit_amount    (numeric) : Debit amount.
--   s_credit_account  (varchar) : Description of the credit account.
--   n_credit_amount   (numeric) : Credit amount.
--   d_gl_date         (date)    : Date of the journal entry.
--   s_memo            (varchar) : Memo text for the entry.
--
-- Returns  : int — always returns 1 on success.
--
-- Usage
--   PERFORM books.insert_journal_entry_basic(
--     'Bank Cheque Account', 500.00,
--     'Accounts Payable', 500.00,
--     '2024-01-15', 'Payment to supplier'
--   );
--
-- Dependencies
--   Functions : books.insert_gl_entry_basic
-- ============================================================
CREATE OR REPLACE FUNCTION books.insert_journal_entry_basic (
s_debit_account varchar(50),
n_debit_amount numeric(16,2),
s_credit_account varchar(50),
n_credit_amount numeric(16,2),
d_gl_date date,
s_memo varchar(256)) 
RETURNS int AS $$ 
BEGIN

	PERFORM books.insert_gl_entry_basic(1::int2, -- JE 
		s_debit_account::varchar, 
		n_debit_amount::numeric(16,2), 
		s_credit_account::varchar, 
		n_credit_amount::numeric(16,2), 
		d_gl_date::date, 
		s_memo::varchar,
		NULL::int4);
	
	RETURN 1;
END;

$$ LANGUAGE plpgsql;