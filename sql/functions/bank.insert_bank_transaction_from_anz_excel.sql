DROP FUNCTION IF EXISTS bank.insert_bank_transaction_from_anz_excel;

-- ============================================================
-- Function : bank.insert_bank_transaction_from_anz_excel(varchar, varchar)
-- ============================================================
-- Purpose  : Loads bank transactions from the load.anz_excel staging table
--            into bank.transaction, first removing any existing transactions
--            whose transaction and processed dates overlap with the loaded data,
--            then returning the new import identifier.
--
-- Parameters
--   s_bank_account_number        (varchar) : ANZ account number to match; optional
--                                            if s_bank_account_friendly_name is provided.
--   s_bank_account_friendly_name (varchar) : Friendly name of the account to match;
--                                            optional if s_bank_account_number is provided.
--
-- Returns  : int8 — the import identifier assigned to this batch of transactions.
--
-- Usage
--   SELECT bank.insert_bank_transaction_from_anz_excel(
--       s_bank_account_number := '01-0123-0123456-00'
--   );
--
-- Dependencies
--   Tables    : bank.account, bank.transaction, load.anz_excel
--   Sequences : bank.import_identifier
-- ============================================================
CREATE OR REPLACE FUNCTION bank.insert_bank_transaction_from_anz_excel ( s_bank_account_number varchar(56) = NULL,
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
		-- Match on account number if provided
		a.external_unique_identifier = COALESCE( rtrim(s_bank_account_number),
		a.external_unique_identifier )
		-- Match on friendly name if provided
		AND a.external_friendly_name = COALESCE( rtrim(s_bank_account_friendly_name),
		a.external_friendly_name )
		-- Ensure at least one search parameter was passed
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

-- remove any existing bank transactions, based on transaction and processed_dates matching in the imported data
WITH distinct_loaded_dates AS (
SELECT
	CAST( a."Transaction Date" AS date ) AS transaction_date,
	CAST( a."Processed Date" AS date ) AS processed_date
FROM
	load.anz_excel a ) DELETE FROM
	bank.transaction t
		USING distinct_loaded_dates
		WHERE
			distinct_loaded_dates.transaction_date = t.transaction_date
			AND distinct_loaded_dates.processed_date = t.processed_date
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
			CAST( a."Transaction Date" AS date ),
			CAST ( a."Processed Date" AS date ),
			CAST( a."Amount" AS money ),
			CAST( a."Balance" AS money ),
			"To/FROM Account Number",
			a."Type",
			a."Details",
			a."Particulars",
			a."Code",
			a."Reference"
		FROM
			load.anz_excel a;

RETURN n_import_identifier;
END;

$$ LANGUAGE plpgsql;