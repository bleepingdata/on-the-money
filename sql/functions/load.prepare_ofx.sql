DROP FUNCTION IF EXISTS load.prepare_ofx;

CREATE OR REPLACE FUNCTION load.prepare_ofx ( n_bank_account_id int4 = NULL ) RETURNS void AS $$
BEGIN
	-- delete from load.ofx for this account id
	DELETE FROM load.ofx WHERE bank_account_id = n_bank_account_id;

RETURN;
END;

$$ LANGUAGE plpgsql;