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
    t.matched_import_rule_id,
    row_to_json(irfm) "import_rules_fields"
   FROM bank.transaction t
      left join bank.import_rule ir on t.matched_import_rule_id = ir.import_rule_id
      left join bank.import_rule_gl_matrix irgm on ir.import_rule_id = irgm.import_rule_id
      left join bank.import_rule_fields_to_match irfm on t.matched_import_rule_id = irfm.import_rule_id;
