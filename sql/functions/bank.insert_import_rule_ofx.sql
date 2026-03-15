drop function if exists bank.insert_import_rule_ofx;

create or replace function bank.insert_import_rule_ofx
	(s_bank_account varchar(50),
	s_account varchar(50),
	s_other_party_account varchar(50),
	s_type varchar(50),
	s_ofx_name varchar(50),
	s_ofx_memo varchar(255),
	n_priority int2)
returns void as $$
declare n_bank_account_id int;
n_account_id int;
n_other_party_account_id int;
n_import_rule_id int;
begin


	if n_priority is null
    then
    	n_priority=32767;  -- by default, ofx  rules should have a high priority
    end if;

	perform bank.insert_import_rule(s_import_rule_type:='Standard',
	s_bank_account:=s_bank_account,
	s_account:=s_account,
	s_other_party_account:=s_other_party_account,
    s_type:=s_type,
    s_ofx_name:=s_ofx_name,
    s_ofx_memo:=s_ofx_memo,
    n_priority:=n_priority);

	return;
end;
$$ language plpgsql;