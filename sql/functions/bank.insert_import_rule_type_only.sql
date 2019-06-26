drop function if exists bank.insert_import_rule_type_only;

create or replace function bank.insert_import_rule_type_only
	(s_other_party_account varchar(50),
	s_type varchar(50),
	n_priority int2)
returns int as $$
declare 
n_other_party_account_id int;
n_import_rule_id int;
begin

	if n_priority is null
    then
    	select -32768 into n_priority;  -- by default, wildcard rules should have a very low priority in comparison to other rules
    end if;
   
   select account_id into n_other_party_account_id from books.account where description = s_other_party_account;

	if n_other_party_account_id is null
	then 
		raise exception 'unable to insert transaction import rule because s_other_party_account %s cannot be found', s_other_party_account;
		return 0;
	end if;

	insert into bank.import_rule (other_party_account_id, type, priority)
		values (n_other_party_account_id, s_type, n_priority)
	 RETURNING import_rule_id into n_import_rule_id;
	
	return n_import_rule_id;
end;
$$ language plpgsql;