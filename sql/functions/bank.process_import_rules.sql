drop function if exists bank.process_import_rules();

create or replace function bank.process_import_rules ()
RETURNS void AS $$
begin
	
	
	-- First sweep.  Do wildcard rules.
	-- The only field that is matched is the wildcard field and start / end dates of rule. 
	-- The wildcard field is matched to any of details, particulars, code, referenece, ofx_name or ofx_memo.

	update bank."transaction" as t_to_update
	set other_party_account_id = matches.other_party_account_id -- select *
	from 
	(
		select t.bank_account_id, t.transaction_id, ir.other_party_account_id, ir.priority
		from bank."transaction" t
			inner join bank.import_rule ir
					on ir.start_date <= t.processed_date 
					and ir.end_date >= t.processed_date
		where 
			ir.wildcard_field is not null 
			and 
				(
				t.details LIKE ir.wildcard_field
				or t.particulars LIKE ir.wildcard_field
				or t.code LIKE ir.wildcard_field
				or t.reference LIKE ir.wildcard_field
				or t.ofx_name like ir.wildcard_field
				or t.ofx_memo like ir.wildcard_field
				)
			order by ir.priority desc

		) matches
		WHERE t_to_update.transaction_id = matches.transaction_id
			and t_to_update.bank_account_id <> matches.other_party_account_id;
		
	
	-- Second sweep.  Do all other rules. This sweep can overwrite wildcard rules.
	-- Matches bank account (mandatory) and any of type, details, particulars, code or reference.
	
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
			ir.wildcard_field is null
			and
			((t.other_party_bank_account_number = ir.other_party_bank_account_number or ir.other_party_bank_account_number is null)
			and (
					(t.type = ir.type or ir.type is null)
					and (t.details LIKE ir.details or ir.details is null)
					and (t.particulars LIKE ir.particulars or ir.particulars is null)
					and (t.code LIKE ir.code or ir.code is null)
					and (t.reference LIKE ir.reference or ir.reference is null)
					and (t.ofx_name LIKE ir.ofx_name or ir.ofx_name is null)
					and (t.ofx_memo LIKE ir.ofx_memo or ir.ofx_memo is null)
			))
			order by ir.priority desc
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
		where (gl.account_id <> t.bank_account_id  -- get the other side of the transaction
			and gl.account_id <> t.other_party_account_id)
			or (t.other_party_account_id is not null and gl.account_id in (select account_id from books.account where description in ('uncategorised expense', 'uncategorised income')))
	) matches
	where gl.gl_id = matches.gl_id;

END;
$$ language plpgsql;