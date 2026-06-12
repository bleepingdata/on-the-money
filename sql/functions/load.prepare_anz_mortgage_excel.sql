DROP FUNCTION IF EXISTS load.prepare_anz_mortgage_excel;

-- ============================================================
-- Function : load.prepare_anz_mortgage_excel()
-- ============================================================
-- Purpose  : Prepares the load.anz_mortgage_excel staging table for a
--            new ANZ mortgage Excel import by truncating all existing rows.
--
-- Parameters
--   (none)
--
-- Returns  : void
--
-- Usage
--   PERFORM load.prepare_anz_mortgage_excel();
--
-- Dependencies
--   Tables    : load.anz_mortgage_excel
--   Functions : (none)
-- ============================================================
CREATE OR REPLACE FUNCTION load.prepare_anz_mortgage_excel () RETURNS void AS $$
BEGIN
-- truncate the table that will hold the imported data
 TRUNCATE
	TABLE
		load.anz_mortgage_excel;

RETURN;
END;

$$ LANGUAGE plpgsql;