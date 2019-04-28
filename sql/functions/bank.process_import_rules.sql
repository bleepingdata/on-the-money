drop function if exists bank.process_import_rules();

create or replace function bank.process_import_rules ()
RETURNS void AS $$
begin
	
	update bank."transaction" as t_to_update
	set other_party_account_id = matches.other_party_account_id -- select *
	from 
	(
		select t.bank_account_id, t.transaction_id, ir.other_party_account_id
		from bank."transaction" t
			inner join bank.import_rule ir on t.bank_account_id = ir.bank_account_id 
					and ir.start_date <= t.processed_date 
					and ir.end_date >= t.processed_date
		where 
			(t.type = ir.type or ir.type is null)
			and (t.other_party_bank_account_number = ir.other_party_bank_account_number or ir.other_party_bank_account_number is null)
			and (t.details = ir.details or ir.details is null)
			and (t.particulars = ir.particulars or ir.particulars is null)
			and (t.code = ir.code or ir.code is null)
			and (t.reference = ir.reference or ir.reference is null)
		) matches
		WHERE t_to_update.transaction_id = matches.transaction_id
			and t_to_update.bank_account_id <> matches.other_party_account_id;

END;
$$ language plpgsql;