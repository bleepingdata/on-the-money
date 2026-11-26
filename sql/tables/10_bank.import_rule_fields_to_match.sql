/* import_rule fields relating to matching records */
create table if not exists bank.import_rule_fields_to_match
(
    import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_fields_to_match unique,
    bank_account_id int4 null references bank.account(bank_account_id),
    is_deposit boolean default null,
    type varchar(50) null,
    other_party_bank_account_number varchar(56) null,
    details varchar(50) null,
    particulars varchar(50) null,
    code varchar(50) null,
    reference varchar(50) null,
    ofx_name varchar(50) null,
    ofx_memo varchar(255) null,
    wildcard_field varchar(50) null
);
