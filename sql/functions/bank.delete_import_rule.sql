create or replace function bank.delete_import_rule(n_import_rule_id int4)
returns void as $$
begin
    -- Block delete if any transaction or GL entry references this rule
    if exists (
        select 1 from bank.transaction
        where matched_import_rule_id = n_import_rule_id
    ) or exists (
        select 1 from books.general_ledger
        where matched_import_rule_id = n_import_rule_id
    ) then
        raise exception 'Cannot delete rule %: it is referenced by existing transactions or GL entries. Re-categorise those transactions first.', n_import_rule_id;
    end if;

    delete from bank.import_rule_fields_to_match
    where import_rule_id = n_import_rule_id;

    delete from bank.import_rule_gl_matrix
    where import_rule_id = n_import_rule_id;

    delete from bank.import_rule
    where import_rule_id = n_import_rule_id;
end;
$$ language plpgsql;
