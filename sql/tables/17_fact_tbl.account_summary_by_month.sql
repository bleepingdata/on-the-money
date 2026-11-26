create table if not exists fact_tbl.account_summary_by_month
(
    account_id int not null,
    year int not null,
    month_number int not null,
    month_end_date date not null,
    debit_amount numeric(16,2),
    credit_amount numeric(16,2),
    debit_amount_running_total numeric(16,2),
    credit_amount_running_total numeric(16,2),
    balance numeric(16,2)
);
