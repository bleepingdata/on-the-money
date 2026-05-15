DROP FUNCTION IF EXISTS load.prepare_ofx;

-- ============================================================
-- Function : load.prepare_ofx(int4)
-- ============================================================
-- Purpose  : Prepares the load.ofx staging table for a new OFX import
--            by deleting all existing rows for the specified bank account.
--
-- Parameters
--   n_bank_account_id  (int4) : ID of the bank account whose staged OFX
--                               rows should be removed before re-import.
--
-- Returns  : void
--
-- Usage
--   PERFORM load.prepare_ofx(1);
--
-- Dependencies
--   Tables    : load.ofx
--   Functions : (none)
-- ============================================================
CREATE OR REPLACE FUNCTION load.prepare_ofx ( n_bank_account_id int4 = NULL ) RETURNS void AS $$
BEGIN
	-- delete from load.ofx for this account id
	DELETE FROM load.ofx WHERE bank_account_id = n_bank_account_id;

RETURN;
END;

$$ LANGUAGE plpgsql;