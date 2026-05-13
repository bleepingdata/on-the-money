DROP FUNCTION IF EXISTS bank.process_import_rules_for_transaction();

CREATE OR REPLACE FUNCTION bank.process_import_rules_for_transaction (n_transaction_id int8)
RETURNS void AS $$
BEGIN
	-- process all import rules, except for debt.
	

	-- First sweep.  Insert matches from wildcard rules into working table.
	-- The only field that is matched is the wildcard field and start / end dates of rule. 
	-- The wildcard field is matched to any of details, particulars, code, referenece, ofx_name or ofx_memo.

	WITH matched_rules AS
	(
	SELECT t.transaction_id, ir.import_rule_id, ir.priority, ir.start_date, ir.row_creation_date
	FROM bank."transaction" t
		INNER JOIN bank.import_rule ir
				ON ir.start_date <= t.processed_date 
				AND ir.end_date >= t.processed_date
		INNER JOIN bank.import_rule_fields_to_match irf
			ON ir.import_rule_id = irf.import_rule_id
	WHERE 
	    t.transaction_id = n_transaction_id
	    AND (irf.is_deposit IS NULL OR (irf.is_deposit IS TRUE AND t.amount > 0 OR irf.is_deposit IS FALSE AND t.amount < 0))
	    AND irf.wildcard_field IS NOT NULL 
		AND 
			(
			t.details LIKE irf.wildcard_field
			OR t.particulars LIKE irf.wildcard_field
			OR t.code LIKE irf.wildcard_field
			OR t.reference LIKE irf.wildcard_field
			OR t.ofx_name LIKE irf.wildcard_field
			OR t.ofx_memo LIKE irf.wildcard_field
			)
	UNION
	SELECT t.transaction_id, ir.import_rule_id, ir.priority, ir.start_date, ir.row_creation_date
	FROM bank."transaction" t
		INNER JOIN bank.import_rule ir ON ir.start_date <= t.processed_date 
				AND ir.end_date >= t.processed_date
		INNER JOIN bank.import_rule_fields_to_match irf
			ON ir.import_rule_id = irf.import_rule_id
	WHERE 
		t.transaction_id = n_transaction_id
	    AND (irf.is_deposit IS NULL OR (irf.is_deposit IS TRUE AND t.amount > 0 OR irf.is_deposit IS FALSE AND t.amount < 0))
	    AND irf.wildcard_field IS NULL
		AND (t.bank_account_id = irf.bank_account_id OR irf.bank_account_id IS NULL)
		AND (
				(t.type = irf.type OR irf.type IS NULL)
				AND (t.details LIKE irf.details OR irf.details IS NULL)
				AND (t.particulars LIKE irf.particulars OR irf.particulars IS NULL)
				AND (t.code LIKE irf.code OR irf.code IS NULL)
				AND (t.reference LIKE irf.reference OR irf.reference IS NULL)
				AND (t.ofx_name LIKE irf.ofx_name OR irf.ofx_name IS NULL)
				AND (t.ofx_memo LIKE irf.ofx_memo OR irf.ofx_memo IS NULL)
		)
	UNION
	SELECT n_transaction_id AS transaction_id, 0 AS import_rule_id, -32767 AS priority, '1900-01-01' AS start_date, '1900-01-01' AS row_creation_date
	)
	UPDATE bank."transaction" AS t_to_update
	SET matched_import_rule_id = prioritised_matches.import_rule_id
	FROM
	(WITH prioritised_rules AS (
           SELECT m.transaction_id, 
            m.import_rule_id, 
            m.priority, 
            m.start_date,
            m.row_creation_date,
            ROW_NUMBER() OVER(PARTITION BY m.transaction_id
                                 ORDER BY m.priority DESC, start_date ASC, row_creation_date ASC, import_rule_id ASC) AS row_num
           FROM matched_rules m)
	  SELECT pr.transaction_id, pr.import_rule_id
	  FROM prioritised_rules pr
	  	INNER JOIN bank.import_rule r ON pr.import_rule_id = r.import_rule_id
	  WHERE pr.row_num = 1  -- get the matching rule with the highest priority
	 )  prioritised_matches
	 WHERE t_to_update.transaction_id = prioritised_matches.transaction_id;
	
	

END;
$$ LANGUAGE plpgsql;