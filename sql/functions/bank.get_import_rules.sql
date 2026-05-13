DROP FUNCTION IF EXISTS bank.get_import_rules();

CREATE OR REPLACE FUNCTION bank.get_import_rules()
RETURNS TABLE (
    import_rule_id      int4,
    rule_type           varchar,
    priority            int2,
    start_date          date,
    end_date            date,
    bank_account        varchar,
    is_deposit          boolean,
    transaction_type    varchar,
    other_party_bank_account_number varchar,
    details             varchar,
    particulars         varchar,
    code                varchar,
    reference           varchar,
    ofx_name            varchar,
    ofx_memo            varchar,
    wildcard_field      varchar,
    debit_account_1     varchar,
    credit_account_1    varchar,
    debit_account_2     varchar,
    credit_account_2    varchar
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ir.import_rule_id,
        irt.import_rule_type,
        ir.priority,
        ir.start_date,
        ir.end_date,
        ba.description,
        irfm.is_deposit,
        irfm.type,
        irfm.other_party_bank_account_number,
        irfm.details,
        irfm.particulars,
        irfm.code,
        irfm.reference,
        irfm.ofx_name,
        irfm.ofx_memo,
        irfm.wildcard_field,
        d1.description,
        c1.description,
        d2.description,
        c2.description
    FROM bank.import_rule ir
    JOIN bank.import_rule_type irt
        ON ir.import_rule_type_id = irt.import_rule_type_id
    LEFT JOIN bank.import_rule_fields_to_match irfm
        ON ir.import_rule_id = irfm.import_rule_id
    LEFT JOIN bank.import_rule_gl_matrix irgm
        ON ir.import_rule_id = irgm.import_rule_id
    LEFT JOIN bank.account ba
        ON irfm.bank_account_id = ba.bank_account_id
    LEFT JOIN books.account d1
        ON irgm.debit_account_id_1 = d1.account_id
    LEFT JOIN books.account c1
        ON irgm.credit_account_id_1 = c1.account_id
    LEFT JOIN books.account d2
        ON irgm.debit_account_id_2 = d2.account_id
    LEFT JOIN books.account c2
        ON irgm.credit_account_id_2 = c2.account_id
    ORDER BY ir.import_rule_id;
END;
$$ LANGUAGE plpgsql;
