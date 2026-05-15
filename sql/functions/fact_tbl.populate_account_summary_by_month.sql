DROP FUNCTION IF EXISTS fact_tbl.populate_account_summary_by_month;

-- ============================================================
-- Function : fact_tbl.populate_account_summary_by_month()
-- ============================================================
-- Purpose  : Rebuilds the fact_tbl.account_summary_by_month fact table
--            by truncating it and repopulating it with per-account monthly
--            debit, credit, and running-balance totals derived from the
--            general ledger, including months with no transactions.
--
-- Parameters
--   (none)
--
-- Returns  : void
--
-- Usage
--   PERFORM fact_tbl.populate_account_summary_by_month();
--
-- Dependencies
--   Tables    : books.general_ledger, books.account, dimension.dates,
--               fact_tbl.account_summary_by_month
--   Functions : (none)
-- ============================================================
 CREATE OR REPLACE FUNCTION fact_tbl.populate_account_summary_by_month() RETURNS void AS $$ 
BEGIN 
	
	TRUNCATE TABLE
		fact_tbl.account_summary_by_month;
	
WITH monthly_summary AS 
(
 SELECT
	gl.account_id,
	gl.gl_date,
	gl.debit_amount,
	gl.credit_amount
FROM
	books.general_ledger gl
UNION ALL SELECT
	a.account_id,
	d.month_year_date AS gl_date,
	0 AS debit_amount,
	0 AS credit_amount
FROM
	dimension.dates d
INNER JOIN books.account a ON
	d.datekey >= a.open_date
LEFT JOIN books.general_ledger gl ON
	d.datekey = gl.gl_date
	AND a.account_id = gl.account_id
WHERE
	gl.account_id IS NULL
	AND d.datekey >= (
	SELECT
		min(gl_date)
	FROM
		books.general_ledger)
	AND d.month_year_date <= (
	SELECT
		(date_trunc('month', max(gl_date)) + interval '1 month' - interval '1 day')::date
	FROM
		books.general_ledger)
GROUP BY a.account_id, d.month_year_date
)
 INSERT INTO
		fact_tbl.account_summary_by_month ( account_id, year, month_number, month_end_date, debit_amount, credit_amount, debit_amount_running_total, credit_amount_running_total, balance ) 
		SELECT
			transactions.account_id,
			transactions.year,
			transactions.month_number,
			transactions.month_end_date,
			transactions.debit_amount,
			transactions.credit_amount,
			SUM ( transactions.debit_amount ) OVER ( PARTITION BY transactions.account_id ORDER BY transactions.year, transactions.month_number) AS debit_amount_running_total,
			SUM ( transactions.credit_amount ) OVER ( PARTITION BY transactions.account_id ORDER BY transactions.year, transactions.month_number) AS credit_amount_running_total,
			SUM ( transactions.debit_amount - transactions.credit_amount) OVER ( PARTITION BY transactions.account_id ORDER BY transactions.year, transactions.month_number) AS balance
		FROM
			( SELECT
				account_id, 
				date_part( 'year', gl_date ) AS year, 
				date_part( 'month', gl_date ) AS month_number, 
				date_trunc( 'month', max( gl_date )) + interval '1 month' - interval '1 day' AS month_end_date, 
				SUM(debit_amount) AS debit_amount, 
				SUM(credit_amount) AS credit_amount
			FROM
				monthly_summary
			GROUP BY
				account_id, date_part( 'year', gl_date ), date_part( 'month', gl_date ) 
				) transactions
		ORDER BY
			transactions.account_id,
			transactions.year,
			transactions.month_number;

 RETURN;


END;

 $$ LANGUAGE plpgsql;