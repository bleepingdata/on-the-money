drop function if exists bank.process_import_rules_for_transaction();

create or replace function bank.process_import_rules_for_transaction (n_transaction_id int8)
RETURNS void AS $$
begin
	-- process all import rules, except for debt.
	

	-- First sweep.  Insert matches from wildcard rules into working table.
	-- The only field that is matched is the wildcard field and start / end dates of rule. 
	-- The wildcard field is matched to any of details, particulars, code, referenece, ofx_name or ofx_memo.

	with matched_rules as
	(
	select t.transaction_id, ir.import_rule_id, ir.priority, ir.start_date, ir.row_creation_date
	from bank."transaction" t
		inner join bank.import_rule ir
				on ir.start_date <= t.processed_date 
				and ir.end_date >= t.processed_date
		INNER JOIN bank.import_rule_fields_to_match irf
			ON ir.import_rule_id = irf.import_rule_id
	where 
	    t.transaction_id = n_transaction_id
	    and (irf.is_deposit is null or (irf.is_deposit is true and t.amount > 0 or irf.is_deposit is false and t.amount < 0))
	    and irf.wildcard_field is not null 
		and 
			(
			t.details LIKE irf.wildcard_field
			or t.particulars LIKE irf.wildcard_field
			or t.code LIKE irf.wildcard_field
			or t.reference LIKE irf.wildcard_field
			or t.ofx_name like irf.wildcard_field
			or t.ofx_memo like irf.wildcard_field
			)
	union
	select t.transaction_id, ir.import_rule_id, ir.priority, ir.start_date, ir.row_creation_date
	from bank."transaction" t
		inner join bank.import_rule ir on ir.start_date <= t.processed_date 
				and ir.end_date >= t.processed_date
		INNER JOIN bank.import_rule_fields_to_match irf
			ON ir.import_rule_id = irf.import_rule_id
	where 
		t.transaction_id = n_transaction_id
	    and (irf.is_deposit is null or (irf.is_deposit is true and t.amount > 0 or irf.is_deposit is false and t.amount < 0))
	    and irf.wildcard_field is null
		and (t.bank_account_id = irf.bank_account_id or irf.bank_account_id is null)
		and (
				(t.type = irf.type or irf.type is null)
				and (t.details LIKE irf.details or irf.details is null)
				and (t.particulars LIKE irf.particulars or irf.particulars is null)
				and (t.code LIKE irf.code or irf.code is null)
				and (t.reference LIKE irf.reference or irf.reference is null)
				and (t.ofx_name LIKE irf.ofx_name or irf.ofx_name is null)
				and (t.ofx_memo LIKE irf.ofx_memo or irf.ofx_memo is null)
		)
	union
	select n_transaction_id as transaction_id, 0 as import_rule_id, -32767 as priority, '1900-01-01' as start_date, '1900-01-01' as row_creation_date
	)
	update bank."transaction" as t_to_update
	set matched_import_rule_id = prioritised_matches.import_rule_id
	from
	(WITH prioritised_rules AS (
           SELECT m.transaction_id, 
            m.import_rule_id, 
            m.priority, 
            m.start_date,
            m.row_creation_date,
            ROW_NUMBER() OVER(PARTITION BY m.transaction_id
                                 ORDER BY m.priority desc, start_date asc, row_creation_date asc, import_rule_id asc) AS row_num
           FROM matched_rules m)
	  SELECT pr.transaction_id, pr.import_rule_id
	  FROM prioritised_rules pr
	  	inner join bank.import_rule r on pr.import_rule_id = r.import_rule_id
	  WHERE pr.row_num = 1  -- get the matching rule with the highest priority
	 )  prioritised_matches
	 where t_to_update.transaction_id = prioritised_matches.transaction_id;
	
	

END;
$$ language plpgsql;