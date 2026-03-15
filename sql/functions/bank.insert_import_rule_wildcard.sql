drop function if exists bank.insert_import_rule_wildcard;

create or replace function bank.insert_import_rule_wildcard
	(s_account varchar(50),
	s_other_party_account varchar(50),
	s_wildcard_field varchar(50),
	n_priority int2 default null)
returns void as $$
declare 
n_account_id int;
n_other_party_account_id int;
n_import_rule_id int;
begin

	if n_priority is null
    then
    	n_priority=0;  -- by default, wildcard rules should have a low priority in comparison to other rules
    end if;
   
	perform bank.insert_import_rule(s_bank_account:=null,
	s_import_rule_type:='Standard',
	s_account:=s_account,
	s_other_party_account:=s_other_party_account,
    s_wildcard_field:=s_wildcard_field,
    n_priority:=n_priority);
	
	return;
end;
$$ language plpgsql;