create or replace function bank.insert_import_rule
	(s_import_rule_type varchar(50),
	n_priority smallint default 0
	)
returns int as $$
declare n_import_rule_type_id SMALLINT;
n_import_rule_id int;
begin
   
    SELECT import_rule_type_id INTO n_import_rule_type_id FROM bank.import_rule_type WHERE description = s_import_rule_type;

	insert into bank.import_rule (import_rule_type_id, priority)
	values (n_import_rule_type_id, n_priority)
	 RETURNING import_rule_id into n_import_rule_id;
	
	return n_import_rule_id;
end;
$$ language plpgsql;