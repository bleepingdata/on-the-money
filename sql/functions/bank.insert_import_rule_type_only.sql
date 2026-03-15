drop function if exists bank.insert_import_rule_type_only;

create or replace function bank.insert_import_rule_type_only
	(s_account varchar(50),
	s_other_party_account varchar(50),
	s_type varchar(50),
	n_priority int2)
returns void as $$
declare 
n_other_party_account_id int;
n_import_rule_id int;
begin

	if n_priority is null
    then
    	select -32768 into n_priority;  -- by default, wildcard rules should have a very low priority in comparison to other rules
    end if;
   
	perform bank.insert_import_rule(s_bank_account:=null,
	s_import_rule_type:='Standard',
	s_account:=s_account,
	s_other_party_account:=s_other_party_account,
    s_type:=s_type,
    n_priority:=n_priority);
	
	return;
end;
$$ language plpgsql;