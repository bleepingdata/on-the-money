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
			and (t.details LIKE ir.details or ir.details is null)
			and (t.particulars LIKE ir.particulars or ir.particulars is null)
			and (t.code LIKE ir.code or ir.code is null)
			and (t.reference LIKE ir.reference or ir.reference is null)
		) matches
		WHERE t_to_update.transaction_id = matches.transaction_id
			and t_to_update.bank_account_id <> matches.other_party_account_id;
	
	-- GL transactions where the account id does not match the import rules (usually because new rules have been added)
	update books.general_ledger as gl
		set account_id = matches.other_party_account_id
		from 
		(
		select gl.gl_id, gl.account_id, t.other_party_account_id 
		from books.general_ledger gl 
		inner join bank."transaction" t on gl.source_identifier = t.transaction_id
		where (gl.account_id <> t.bank_account_id
			and gl.account_id <> t.other_party_account_id)
			or (t.other_party_account_id is not null and gl.account_id in (select account_id from books.account where description in ('uncategorised expense', 'uncategorised income')))
	) matches
	where gl.gl_id = matches.gl_id;

END;
$$ language plpgsql;