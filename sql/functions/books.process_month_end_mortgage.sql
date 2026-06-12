DROP FUNCTION IF EXISTS books.process_month_end_mortgage;

-- ============================================================
-- Function : books.process_month_end_mortgage(int4, int4, date)
-- ============================================================
-- Purpose  : Performs the month-end close for a mortgage by transferring
--            any positive balance in the interest payable account into the
--            loan principal account via a GL journal entry. Should be run
--            after all transactions for the month have been imported.
--
-- Parameters
--   n_loan_principal_account_id   (int4) : Account ID of the loan principal.
--   n_interest_payable_account_id (int4) : Account ID of the interest payable.
--   d_month_end_date              (date) : The last day of the month being closed.
--
-- Returns  : void
--
-- Usage
--   PERFORM books.process_month_end_mortgage(15, 22, '2024-01-31');
--
-- Dependencies
--   Tables    : books.general_ledger
--   Functions : books.get_account_balance_at_date, books.insert_gl_entry_basic
-- ============================================================
CREATE OR REPLACE FUNCTION books.process_month_end_mortgage (n_loan_principal_account_id int4, n_interest_payable_account_id int4, d_month_end_date date)
RETURNS void AS $$
DECLARE n_balance numeric(16,2);
d_interest_payable_gl_date date;
BEGIN
/* 
 
  transfer any non-negative mortgage interest payable balances into the related principal account.
  
  this process must run after all transactions for the month have been imported, otherwise 
  unexpected results may happen.
  
 */
	
	SELECT books.get_account_balance_at_date(n_interest_payable_account_id, d_month_end_date) INTO n_balance;
	
	IF (n_balance > 0)
	THEN
	
		SELECT max(gl_date) INTO d_interest_payable_gl_date
		FROM books.general_ledger
		WHERE account_id = n_interest_payable_account_id
			AND gl_date <= d_month_end_date;
	
		PERFORM books.insert_gl_entry_basic(
			n_gl_type_id:=1::int2, -- JE 
			n_debit_account_id:=n_loan_principal_account_id::int, 
			n_debit_amount:=n_balance::numeric(16,2), 
			n_credit_account_id:=n_interest_payable_account_id::int, 
			n_credit_amount:=n_balance::numeric(16,2), 
			d_gl_date:=d_interest_payable_gl_date::date, 
			s_memo:='Interest Payable balance to Principal'::varchar);
	
	END IF;
	
	RETURN;
END;
$$ LANGUAGE plpgsql;