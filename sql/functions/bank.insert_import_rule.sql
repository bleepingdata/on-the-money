create or replace function bank.insert_import_rule
	(s_bank_account varchar(50),
	s_account varchar(50),
	s_other_party_account varchar(50),
	s_import_rule_type varchar(50) default 'Standard',
	s_account_2 varchar(50) default null,
	s_other_party_account_2 varchar(50) default null,
	n_priority smallint default 0,
	s_type varchar(50) default null,
	s_other_party_bank_account_number varchar(56) default null,
	s_details varchar(50) default null,
	s_particulars varchar(50) default null,
	s_code varchar(50) default null,
	s_reference varchar(50) default null,
    s_ofx_name varchar(50) default null,
	s_ofx_memo varchar(255) default null,
	s_wildcard_field varchar(50) default null
	)
returns int as $$
declare n_import_rule_type_id SMALLINT;
n_bank_account_id int;
n_account_id int;
n_account_id_2 int;
n_other_party_account_id int;
n_other_party_account_id_2 int;
n_import_rule_id int;
begin
   
	select bank_account_id into n_bank_account_id from bank.account where description = s_bank_account;
    select account_id into n_account_id from books.account where description = s_account;
	select account_id into n_other_party_account_id from books.account where description = s_other_party_account;
    select account_id into n_account_id_2 from books.account where description = s_account_2;
    select account_id into n_other_party_account_id_2 from books.account where description = s_other_party_account_2;
    SELECT import_rule_type_id INTO n_import_rule_type_id FROM bank.import_rule_type WHERE description = s_import_rule_type;
   
	if n_account_id is null or n_other_party_account_id is NULL OR (s_other_party_account_2 IS NOT NULL AND n_other_party_account_id is null)
	then 
		raise exception 'unable to insert transaction import rule because either s_account %s or s_other_party_account %s cannot be found or s_other_party_account_2 %s is non null and does not match an account id', s_bank_account, s_other_party_account, s_other_party_account_2;
		return 0;
	end if;

	insert into bank.import_rule (import_rule_type_id, bank_account_id, account_id, other_party_account_id, other_party_account_id_2, priority, type, other_party_bank_account_number, details, particulars, code, reference)
		values (n_import_rule_type_id, n_bank_account_id, n_account_id, n_other_party_account_id, n_other_party_account_id_2, n_priority, s_type, s_other_party_bank_account_number, s_details, s_particulars, s_code, s_reference)
	 RETURNING import_rule_id into n_import_rule_id;
	
	return n_import_rule_id;
end;
$$ language plpgsql;