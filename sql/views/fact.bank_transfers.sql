drop view if exists fact.bank_transfers;

create or replace view fact.bank_transfers
AS
select gl.gl_id, 
	gl.gl_type_id, 
	gl.gl_date, 
	gl.gl_grouping_id, 
	gl.row_creation_date, 
	gl.account_id, 
	gl_other_party.account_id as other_party_account_id,
	a_other_party.description as other_party_description,
	gl.debit_amount, 
	gl.credit_amount, 
	gl.memo, 
	gl.bank_transaction_id
from books.general_ledger gl
inner join books.account a_bank_transfers 
	on gl.account_id = a_bank_transfers.account_id
inner join books.general_ledger gl_other_party 
	on gl.gl_grouping_id = gl_other_party.gl_grouping_id 
		and gl_other_party.account_id <> gl.account_id
inner join books.account a_other_party 
	on gl_other_party.account_id = a_other_party.account_id
where a_bank_transfers.description='Bank Transfers'
;
