DROP FUNCTION IF EXISTS books.get_account_balance_at_date;

CREATE OR REPLACE FUNCTION books.get_account_balance_at_date (n_account_id int, d_date date)
RETURNS decimal(16,2) AS $$
DECLARE n_balance decimal(16,2);
BEGIN
/* 
 get the balance for an account at a date, taking the opening balance into account
 */

	
	SELECT SUM(gl.debit_amount) - SUM(gl.credit_amount) INTO n_balance
		FROM books.general_ledger  gl
		WHERE gl.gl_date <= d_date
			AND gl.account_id = n_account_id
		GROUP BY gl.account_id;
                                   
	SELECT COALESCE(n_balance, 0) INTO n_balance;

	RETURN (n_balance);
END;
$$ LANGUAGE plpgsql;
