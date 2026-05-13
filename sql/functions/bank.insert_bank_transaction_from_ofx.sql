DROP FUNCTION IF EXISTS bank.insert_bank_transaction_from_ofx;

CREATE OR REPLACE FUNCTION bank.insert_bank_transaction_from_ofx ( n_bank_account_id int4 = NULL ) 
RETURNS int8 AS $$ 
DECLARE n_import_identifier int8;
BEGIN

SELECT
	nextval('bank.import_identifier') INTO
		n_import_identifier;

WITH distinct_loaded_dates AS (
SELECT
	CAST( a.dtposted AS date ) AS transaction_date
FROM
	load.ofx a
WHERE a.bank_account_id = n_bank_account_id) DELETE FROM
	bank.transaction t
		USING distinct_loaded_dates
		WHERE
			distinct_loaded_dates.transaction_date = t.transaction_date
			AND t.bank_account_id = n_bank_account_id;

-- add to staging tables
 INSERT INTO
		bank.transaction ( bank_account_friendly_name,
		bank_account_number,
		bank_account_id,
		import_identifier,
		import_datetime,
		transaction_date,
		processed_date,
		amount,
		type,
		ofx_name,
		ofx_memo) SELECT
			a.external_friendly_name,
			a.external_unique_identifier,
			a.bank_account_id,
			n_import_identifier,
			now(),
			CAST( o.dtposted AS date ),
			CAST ( o.dtposted AS date ),
			CAST( o.trnamt AS money ),
			o.trntype,
			o.name,
			o.memo
		FROM
			load.ofx o
			INNER JOIN bank.account a ON o.bank_account_id = a.bank_account_id
		WHERE o.bank_account_id=n_bank_account_id;

RETURN n_import_identifier;
END;

$$ LANGUAGE plpgsql;