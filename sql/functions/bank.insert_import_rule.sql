create or replace function bank.insert_import_rule
	(s_bank_account varchar(50),
	s_account varchar(50),
	s_other_party_account varchar(50),
	s_type varchar(50),
	s_other_party_bank_account_number varchar(56),
	s_details varchar(50),
	s_particulars varchar(50),
	s_code varchar(50),
	s_reference varchar(50))
returns int as $$
declare n_bank_account_id int;
n_account_id int;
n_other_party_account_id int;
n_import_rule_id int;
begin

	select bank_account_id into n_bank_account_id from bank.account where description = s_bank_account;
    select account_id into n_account_id from books.account where description = s_account;
	select account_id into n_other_party_account_id from books.account where description = s_other_party_account;

	if n_account_id is null or n_other_party_account_id is null
	then 
		raise exception 'unable to insert transaction import rule because either s_account %s or s_other_party_account %s cannot be found', s_bank_account, s_other_party_account;
		return 0;
	end if;

	insert into bank.import_rule (bank_account_id, account_id, other_party_account_id, type, other_party_bank_account_number, details, particulars, code, reference)
		values (n_bank_account_id, n_account_id, n_other_party_account_id, s_type, s_other_party_bank_account_number, s_details, s_particulars, s_code, s_reference)
	 RETURNING import_rule_id into n_import_rule_id;
	
	return n_import_rule_id;
end;
$$ language plpgsql;