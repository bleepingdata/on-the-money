drop function if exists bank.insert_import_rule_wildcard;

create or replace function bank.insert_import_rule_wildcard
	(s_other_party_account varchar(50),
	s_wildcard_field varchar(50))
returns int as $$
declare 
n_other_party_account_id int;
n_import_rule_id int;
begin

	select account_id into n_other_party_account_id from books.account where description = s_other_party_account;

	if n_other_party_account_id is null
	then 
		raise exception 'unable to insert transaction import rule because s_other_party_account %s cannot be found', s_other_party_account;
		return 0;
	end if;

	insert into bank.import_rule (other_party_account_id, wildcard_field)
		values (n_other_party_account_id, s_wildcard_field)
	 RETURNING import_rule_id into n_import_rule_id;
	
	return n_import_rule_id;
end;
$$ language plpgsql;