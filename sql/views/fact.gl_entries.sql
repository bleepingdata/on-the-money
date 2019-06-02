drop view if exists fact.gl_entries;

create or replace view fact.gl_entries
AS
select gl_id, 
	gl_type_id, 
	gl_date, 
	gl_grouping_id, 
	row_creation_date, 
	account_id, 
	debit_amount, 
	credit_amount, 
	memo, 
	source_identifier
from books.general_ledger
;
