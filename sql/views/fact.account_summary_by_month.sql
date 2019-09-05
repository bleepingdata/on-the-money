drop view if exists fact.account_summary_by_month;

create or replace view fact.account_summary_by_month
AS
select account_id, 
	year, 
	month_number, 
	month_end_date, 
	debit_amount, 
	lag(debit_amount, 1) over (order by account_id, year, month_number) as debit_amount_last_month,
	credit_amount, 
	lag(credit_amount, 1) over (order by account_id, year, month_number) as credit_amount_last_month,
	debit_amount_running_total, 
	credit_amount_running_total, 
	balance, 
	lag(balance, 1) over (order by account_id, year, month_number) as balance_last_month 
from fact_tbl.account_summary_by_month;
