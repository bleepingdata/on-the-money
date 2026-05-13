DROP FUNCTION IF EXISTS load.prepare_anz_excel;

CREATE OR REPLACE FUNCTION load.prepare_anz_excel ( s_bank_account_number varchar(56) = NULL,
s_bank_account_friendly_name varchar(256) = NULL ) RETURNS void AS $$ DECLARE n_account_id int;
BEGIN
-- truncate the table that will hold the imported data
 TRUNCATE
	TABLE
		load.anz_excel;

RETURN;
END;

$$ LANGUAGE plpgsql;