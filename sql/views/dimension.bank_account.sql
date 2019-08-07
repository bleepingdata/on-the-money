drop view if exists dimension.bank_account;

create or replace view dimension.bank_account
AS
select a.bank_account_id, a.description, a.open_date, a.close_date
from bank.account a;