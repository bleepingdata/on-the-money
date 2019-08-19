DROP FUNCTION IF EXISTS bank.insert_import_rule_gl_rules_loan_repayment;

create or replace function bank.insert_import_rule_gl_rules_loan_repayment
	(s_interest_payable_account varchar(50),
	s_loan_principal_account varchar(50),
	s_cash_account varchar(50),
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
declare n_import_rule_type_id SMALLINT;
n_interest_payable_account_id int;
n_loan_principal_account_id int;
n_cash_account_id int;
n_import_rule_id int;
begin
   
    select account_id into n_interest_payable_account_id from books.account where description = s_interest_payable_account;
	select account_id into n_loan_principal_account_id from books.account where description = s_loan_principal_account;
    select account_id into n_cash_account_id from books.account where description = s_cash_account;
   
	if (n_interest_payable_account_id is null or n_loan_principal_account_id is null or n_cash_account_id is null)
	then 
		raise exception 'unable to insert import rule because interest payable account %s or loan principal account %s or cash account %s cannot be found', s_interest_payable_account, s_loan_principal_account, s_cash_account;
		return;
	end if;

	SELECT bank.insert_import_rule(s_import_rule_type:='loan-repayment', n_priority:=n_priority) into n_import_rule_id;

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

	insert into bank.import_rule_gl_matrix (import_rule_id, debit_account_id_1, credit_account_id_1, debit_account_id_2)
		values (n_import_rule_id, 
				n_interest_payable_account_id, 
				n_cash_account_id, 
				n_loan_principal_account_id);
		
	return;
end;
$$ language plpgsql;