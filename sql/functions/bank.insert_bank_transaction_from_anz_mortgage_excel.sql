DROP FUNCTION IF EXISTS bank.insert_bank_transaction_from_anz_mortgage_excel;

-- ============================================================
-- Function : bank.insert_bank_transaction_from_anz_mortgage_excel(varchar, varchar)
-- ============================================================
-- Purpose  : Loads mortgage transactions from the load.anz_mortgage_excel staging
--            table into bank.transaction, first removing any existing transactions
--            whose transaction date overlaps with the loaded data,
--            then returning the new import identifier.
--
-- Parameters
--   s_bank_account_number        (varchar) : ANZ mortgage account number; optional
--                                            if s_bank_account_friendly_name is provided.
--   s_bank_account_friendly_name (varchar) : Friendly name of the account to match;
--                                            optional if s_bank_account_number is provided.
--
-- Returns  : int8 — the import identifier assigned to this batch of transactions.
--
-- Usage
--   SELECT bank.insert_bank_transaction_from_anz_mortgage_excel(
--       s_bank_account_friendly_name := 'ANZ Mortgage'
--   );
--
-- Dependencies
--   Tables    : bank.account, bank.transaction, load.anz_mortgage_excel
--   Sequences : bank.import_identifier
-- ============================================================
CREATE OR REPLACE FUNCTION bank.insert_bank_transaction_from_anz_mortgage_excel ( s_bank_account_number varchar(56) = NULL,
s_bank_account_friendly_name varchar(256) = NULL ) 
RETURNS int8 AS $$ 
DECLARE n_bank_account_id int;
n_import_identifier int8;
BEGIN

 SELECT
	a.bank_account_id INTO
		n_bank_account_id
	FROM
		bank.account a
	WHERE
		a.external_unique_identifier = COALESCE( rtrim(s_bank_account_number),
		a.external_unique_identifier )
		AND a.external_friendly_name = COALESCE( rtrim(s_bank_account_friendly_name),
		a.external_friendly_name )
		AND ( s_bank_account_number IS NOT NULL
		OR s_bank_account_friendly_name IS NOT NULL );

IF n_bank_account_id IS NULL THEN RAISE EXCEPTION 'Nonexistent s_bank_account_number or s_bank_account_friendly_name --> %, %',
s_bank_account_number,
s_bank_account_friendly_name
	USING HINT = 'Please check incoming parameters for s_bank_account_number and s_bank_account_friendly_name';
END IF;

SELECT
	nextval('bank.import_identifier') INTO
		n_import_identifier;

WITH distinct_loaded_dates AS (
SELECT
	CAST( a."Date" AS date ) AS transaction_date
FROM
	load.anz_mortgage_excel a ) 
DELETE FROM
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
		balance,
		other_party_bank_account_number,
		type,
		details,
		particulars,
		code,
		reference ) SELECT
			a.bank_account_friendly_name,
			a.bank_account_number,
			n_bank_account_id,
			n_import_identifier,
			now(),
			CAST( a."Date" AS date ),
			CAST ( a."Date" AS date ),
			CAST( a."Amount" AS money ),
			CAST( a."Balance" AS money ),
			NULL,
			NULL,
			a."Details",
			NULL,
			NULL,
			NULL
		FROM
			load.anz_mortgage_excel a;

RETURN n_import_identifier;
END;

$$ LANGUAGE plpgsql;