DROP FUNCTION IF EXISTS load.prepare_anz_mortgage_excel;

CREATE OR REPLACE FUNCTION load.prepare_anz_mortgage_excel () RETURNS void AS $$
BEGIN
-- truncate the table that will hold the imported data
 TRUNCATE
	TABLE
		load.anz_mortgage_excel;

RETURN;
END;

$$ LANGUAGE plpgsql;