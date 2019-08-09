drop function if exists bank.process_import_rules();

create or replace function bank.process_import_rules ()
RETURNS void AS $$
begin
	
	-- clear out table that holds the set of all matches.
	truncate table working.import_rule_matches;

	-- First sweep.  Insert matches from wildcard rules into working table.
	-- The only field that is matched is the wildcard field and start / end dates of rule. 
	-- The wildcard field is matched to any of details, particulars, code, referenece, ofx_name or ofx_memo.

	insert into working.import_rule_matches (transaction_id, import_rule_id, rule_priority, rule_start_date, rule_row_creation_date)
	select t.transaction_id, ir.import_rule_id, ir.priority, ir.start_date, ir.row_creation_date
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
			);

		
	
	-- Second sweep.  Do all other rules. This sweep can overwrite wildcard rules.
	-- Matches bank account (mandatory) and any of type, details, particulars, code or reference.
	
	insert into working.import_rule_matches (transaction_id, import_rule_id, rule_priority, rule_start_date, rule_row_creation_date)
	select t.transaction_id, ir.import_rule_id, ir.priority, ir.start_date, ir.row_creation_date
	from bank."transaction" t
		inner join bank.import_rule ir on ir.start_date <= t.processed_date 
				and ir.end_date >= t.processed_date
	where 
		ir.wildcard_field is null
		and (t.bank_account_id = ir.bank_account_id or ir.bank_account_id is null)
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
		));

	update bank."transaction" as t_to_update
	set account_id = coalesce (matches.account_id, t_to_update.account_id), 
		other_party_account_id = matches.other_party_account_id
	from
	(WITH prioritised_rules AS (
           SELECT m.transaction_id, 
            m.import_rule_id, 
            m.rule_priority, 
            m.rule_start_date,
            m.rule_row_creation_date,
            ROW_NUMBER() OVER(PARTITION BY m.transaction_id
                                 ORDER BY m.rule_priority desc, rule_start_date asc, rule_row_creation_date asc, import_rule_id asc) AS row_num
           FROM working.import_rule_matches m)
	  SELECT pr.transaction_id, pr.import_rule_id, r.account_id, r.other_party_account_id
	  FROM prioritised_rules pr
	  	inner join bank.import_rule r on pr.import_rule_id = r.import_rule_id
	  WHERE pr.row_num = 1  -- get the matching rule with the highest priority
	 ) matches
	 where t_to_update.transaction_id = matches.transaction_id
	 	and t_to_update.account_id <> matches.other_party_account_id;
	 
	-- GL transactions where the other party account id does not match the import rules (usually because new rules have been added)
	update books.general_ledger as gl
		set account_id = matches.other_party_account_id
		from 
		(
		select gl.gl_id, gl.account_id, t.other_party_account_id 
		from books.general_ledger gl 
		inner join bank."transaction" t on gl.bank_transaction_id = t.transaction_id
		inner join bank.bank_account_gl_account_link link_account_def 
			on t.bank_account_id = link_account_def.bank_account_id and link_account_def.is_default = true
		where (gl.account_id not in 
				(select account_id from bank.bank_account_gl_account_link where bank_account_id = t.bank_account_id) -- get the other side of the transaction
			and gl.account_id <> t.other_party_account_id)
			or (t.other_party_account_id is not null and gl.account_id in (select account_id from books.account where description in ('uncategorised expense', 'uncategorised income')))
	) matches
	where gl.gl_id = matches.gl_id;

	-- GL transactions where the account id does not match the default link account id
	

END;
$$ language plpgsql;