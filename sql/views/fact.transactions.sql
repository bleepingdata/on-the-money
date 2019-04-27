drop view if exists fact.transaction;

create or replace view fact.transaction
AS
select t.transaction_id, 
	t.bank_account_friendly_name,
	t.bank_account_number,
	t.account_id,
	t.amount,
	t.transaction_date, 
	t.processed_date, 
	t."type", 
	t.other_party_bank_account_number,
	t.reference, 
	t.code, 
	t.particulars, 
	t.details
from bank."transaction" t
;
