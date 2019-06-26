drop function if exists bank.insert_import_rule_ofx;

create or replace function bank.insert_import_rule_ofx
	(s_bank_account varchar(50),
	s_other_party_account varchar(50),
	s_type varchar(50),
	s_ofx_name varchar(50),
	s_ofx_memo varchar(255),
	n_priority int2)
returns int as $$
declare n_bank_account_id int;
n_other_party_account_id int;
n_import_rule_id int;
begin

	if n_priority is null
    then
    	n_priority=32767;  -- by default, ofx  rules should have a high priority
    end if;
    
    select account_id into n_bank_account_id from books.account where description = s_bank_account;
	select account_id into n_other_party_account_id from books.account where description = s_other_party_account;

	if n_other_party_account_id is null
	then 
		raise exception 'unable to insert transaction import rule because s_other_party_account %s cannot be found', s_other_party_account;
		return 0;
	end if;

	insert into bank.import_rule (bank_account_id, other_party_account_id, type, ofx_name, ofx_memo)
		values (n_bank_account_id, n_other_party_account_id, s_type, s_ofx_name, s_ofx_memo)
	 RETURNING import_rule_id into n_import_rule_id;
	
	return n_import_rule_id;
end;
$$ language plpgsql;