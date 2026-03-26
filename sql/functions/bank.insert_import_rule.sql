drop function if exists bank.insert_import_rule;

create or replace function bank.insert_import_rule(
    s_import_rule_type varchar(50),
    n_priority smallint default 0
)
returns int
as $$
declare
    n_import_rule_type_id smallint;
    n_import_rule_id int;
begin
    select import_rule_type_id into n_import_rule_type_id
    from bank.import_rule_type
    where import_rule_type = s_import_rule_type;

    insert into bank.import_rule (import_rule_type_id, priority)
    values (n_import_rule_type_id, n_priority)
    returning import_rule_id into n_import_rule_id;

    return n_import_rule_id;
end;
$$ language plpgsql;