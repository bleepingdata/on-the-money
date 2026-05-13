DROP FUNCTION IF EXISTS books.get_bank_account_id;

CREATE OR REPLACE FUNCTION books.get_bank_account_id ( s_bank_account_number varchar(56) = NULL,
s_bank_account_friendly_name varchar(256) = NULL) RETURNS int4 AS $$ DECLARE n_bank_account_id int4;
BEGIN

	SELECT  bank_account_id INTO n_bank_account_id
	FROM bank.account a 
	WHERE 
		(s_bank_account_number IS NOT NULL OR s_bank_account_friendly_name IS NOT NULL)
		AND
		(
			(external_unique_identifier = s_bank_account_number OR s_bank_account_number IS NULL)
			AND
			(external_friendly_name = s_bank_account_friendly_name OR s_bank_account_friendly_name IS NULL)
		)
	;

RETURN n_bank_account_id;

END;

$$ LANGUAGE plpgsql;