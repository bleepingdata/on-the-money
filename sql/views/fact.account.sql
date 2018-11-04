create or replace view fact.account
AS
select a.accountid, a.description, a.balance, a_t.description as account_type
from books.account a
	inner join books.accounttype a_t on a.accounttypeid = a_t.accounttypeid;