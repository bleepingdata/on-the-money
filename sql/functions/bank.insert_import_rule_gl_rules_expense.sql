DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_expense;

create or replace function bank.insert_import_rule_gl_rules_expense
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
   
	//TODO
	
	return n_import_rule_id;
end;
$$ language plpgsql;