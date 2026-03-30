create or replace function bank.get_import_rules()
returns table (
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
) as $$
begin
    return query
    select
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
    from bank.import_rule ir
    join bank.import_rule_type irt
        on ir.import_rule_type_id = irt.import_rule_type_id
    left join bank.import_rule_fields_to_match irfm
        on ir.import_rule_id = irfm.import_rule_id
    left join bank.import_rule_gl_matrix irgm
        on ir.import_rule_id = irgm.import_rule_id
    left join bank.account ba
        on irfm.bank_account_id = ba.bank_account_id
    left join books.account d1
        on irgm.debit_account_id_1 = d1.account_id
    left join books.account c1
        on irgm.credit_account_id_1 = c1.account_id
    left join books.account d2
        on irgm.debit_account_id_2 = d2.account_id
    left join books.account c2
        on irgm.credit_account_id_2 = c2.account_id
    order by ir.priority, ir.import_rule_id;
end;
$$ language plpgsql;
