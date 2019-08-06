drop view if exists fact.uncategorised_transactions;

create or replace view fact.uncategorised_transactions
AS
select gl.gl_id, gl.account_id, gl.debit_amount, gl.credit_amount, t.transaction_date, t.processed_date, t."type", t.other_party_bank_account_number, reference, t.code, t.particulars, t.details
from books.general_ledger gl
	left join bank."transaction" t on gl.bank_transaction_id = t.transaction_id
where gl.account_id in (select account_id from books.account where description in ('uncategorised income', 'uncategorised expense'))
;
