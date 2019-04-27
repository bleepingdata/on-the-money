drop view if exists dimension.account_type;

create or replace view dimension.account_type
AS
select at.account_type_id, at.description as "account_type"
from books.account_type at;