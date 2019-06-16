drop view if exists fact.transaction;

create or replace view fact.transaction
AS
select t.transaction_id, 
	t.bank_account_friendly_name,
	t.bank_account_number,
	t.bank_account_id,
	t.amount,
	t.balance,
	t.transaction_date, 
	t.processed_date, 
	t."type", 
	json_build_object('Other Party', t.other_party_bank_account_number,
	'Reference', t.reference, 
	'Code', t.code, 
	'Particulars', t.particulars, 
	'Details', t.details) "reference_details",
	json_build_object('ofx_name', t.ofx_name,
			'ofx_memo', t.ofx_memo) "ofx_details"
from bank."transaction" t
;