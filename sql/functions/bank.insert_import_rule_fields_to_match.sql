drop function if exists bank.insert_import_rule_fields_to_match;

create or replace function bank.insert_import_rule_fields_to_match
	(n_import_rule_id int4,
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
returns void as $$
begin
   	
	insert into bank.import_rule_fields_to_match(import_rule_id, type, other_party_bank_account_number, details, particulars, code, reference, ofx_name, ofx_memo, wildcard_field)
	 values (n_import_rule_id, s_type, s_other_party_bank_account_number, s_details, s_particulars, s_code, s_reference, s_ofx_name, s_ofx_memo, s_wildcard_field);

	return;

end;
$$ language plpgsql;