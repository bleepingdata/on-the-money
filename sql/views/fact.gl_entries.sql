drop view if exists fact.gl_entries;

create or replace view fact.gl_entries
AS
select gl_id, 
	gl_type_id, 
	gl_date, 
	gl_grouping_id, 
	gl.row_creation_date, 
	gl.account_id, 
	gl.debit_amount, 
	gl.credit_amount, 
	gl.memo, 
	gl.matched_import_rule_id,
	gl.bank_transaction_id,
	'Type:' || t."type" || ';Details:' || coalesce(t.details, '') || ';Code:' 
		|| coalesce(t.code, '') || ';Particulars:' || coalesce(t.particulars, '') 
		|| ';Reference:' || coalesce(t.reference, '') || ';OFX_Name:' || coalesce(t.ofx_name, '') 
		|| ';OFX_Memo:' || coalesce(t.ofx_memo, '') || ';' AS "bank_details"
from books.general_ledger gl
	LEFT JOIN bank.transaction t ON gl.bank_transaction_id = t.transaction_id

;
