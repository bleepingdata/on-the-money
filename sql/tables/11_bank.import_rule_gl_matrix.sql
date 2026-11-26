create table if not exists bank.import_rule_gl_matrix
(
    import_rule_id int4 not null references bank.import_rule(import_rule_id) constraint uq_bank_import_rule_gl_rules_assets unique,
    debit_account_id_1 int4 not null references books.account(account_id),
    credit_account_id_1 int4 not null references books.account(account_id),
    debit_account_id_2 int4 null references books.account(account_id),
    credit_account_id_2 int4 null references books.account(account_id)
);
