drop view if exists fact."transaction";

CREATE OR REPLACE VIEW fact."transaction"
AS SELECT t.transaction_id,
    t.bank_account_friendly_name,
    t.bank_account_number,
    t.bank_account_id,
    t.amount,
    t.balance,
    t.transaction_date,
    t.processed_date,
    t.other_party_bank_account_number,
    t.type,
    t.details,
    t.particulars,
    t.code,
    t.reference,
    t.ofx_name,
    t.ofx_memo,
    t.matched_import_rule_id
   FROM bank.transaction t;
