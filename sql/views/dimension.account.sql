drop view if exists dimension.account;

create or replace view dimension.account
AS
select a.account_id, a.description, a_t.account_type as account_type, a.open_date, a.close_date
from books.account a
	inner join books.account_type a_t on a.account_type_id = a_t.account_type_id;