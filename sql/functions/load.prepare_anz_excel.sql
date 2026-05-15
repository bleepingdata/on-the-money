DROP FUNCTION IF EXISTS load.prepare_anz_excel;

-- ============================================================
-- Function : load.prepare_anz_excel(varchar, varchar)
-- ============================================================
-- Purpose  : Prepares the load.anz_excel staging table for a new ANZ
--            bank Excel import by truncating all existing rows.
--
-- Parameters
--   s_bank_account_number        (varchar(56))  : Optional bank account number to identify the account.
--   s_bank_account_friendly_name (varchar(256)) : Optional friendly name of the bank account.
--
-- Returns  : void
--
-- Usage
--   PERFORM load.prepare_anz_excel('01-0101-0101010-00', 'ANZ Everyday');
--
-- Dependencies
--   Tables    : load.anz_excel
--   Functions : (none)
-- ============================================================
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