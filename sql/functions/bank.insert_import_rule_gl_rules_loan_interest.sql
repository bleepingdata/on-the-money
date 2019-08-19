DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_equity;

create or replace function bank.insert_import_rule_gl_rules_equity
	(s_bank_account_account varchar(50),
	s_equity_account varchar(50),
	n_priority smallint default 0,
	s_bank_account varchar(50) default null,
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
declare n_import_rule_type_id int2;
n_bank_account_account_id int4;
n_equity_account_id int4;
n_import_rule_id int;
begin
   
    select account_id into n_bank_account_account_id from books.account where description = s_bank_account_account;
	select account_id into n_equity_account_id from books.account where description = s_equity_account;
   
	if (n_bank_account_account_id is null or n_equity_account_id is null)
	then 
		raise exception 'unable to insert import rule because bank''s account %s or equity account %s cannot be found', s_bank_account_account, s_equity_account;
		return;
	end if;

	SELECT bank.insert_import_rule(s_import_rule_type:='equity', n_priority:=n_priority) into n_import_rule_id;

	if n_import_rule_id is null
	then 
		raise exception 'Unable to add row to bank.import_rule for some reason';
		return;
	end if;

	perform bank.insert_import_rule_fields_to_match(
		n_import_rule_id:=n_import_rule_id, 
		s_bank_account:=s_bank_account,
		s_type:=s_type, 
		s_other_party_bank_account_number:=s_other_party_bank_account_number, 
		s_details:=s_details, 
		s_particulars:=s_particulars, 
		s_code:=s_code,
		s_reference:=s_reference,
		s_ofx_name:=s_ofx_name, 
		s_ofx_memo:=s_ofx_memo,
		s_wildcard_field:=s_wildcard_field);

	insert into bank.import_rule_gl_rules_equity (import_rule_id, bank_account_account_id, equity_account_id)
		values (n_import_rule_id, 
				n_bank_account_account_id,
				n_equity_account_id);
			
	return;
end;
$$ language plpgsql;