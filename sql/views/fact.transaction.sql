CREATE OR REPLACE VIEW fact."transaction"
AS SELECT t.transaction_id,
    t.bank_account_friendly_name,
    t.bank_account_number,
    t.bank_account_id,
    t.amount,
    t.balance,
    t.transaction_date,
    t.processed_date,
    t.type,
    t.other_party_bank_account_number,
    t.reference,
    t.code,
    t.particulars,
    t.details
   FROM bank.transaction t;
