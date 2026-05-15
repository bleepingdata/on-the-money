DROP FUNCTION IF EXISTS books.get_bank_account_id;

-- ============================================================
-- Function : books.get_bank_account_id(varchar, varchar)
-- ============================================================
-- Purpose  : Looks up and returns the internal bank_account_id by matching
--            against the external account number, the friendly name, or both.
--            At least one of the two parameters must be non-NULL.
--
-- Parameters
--   s_bank_account_number        (varchar) : External unique identifier
--                                            (e.g. bank account number).
--   s_bank_account_friendly_name (varchar) : Human-readable account name.
--
-- Returns  : int4 — the matching bank_account_id, or NULL if not found.
--
-- Usage
--   SELECT books.get_bank_account_id('12-3456-7890123-00', NULL);
--   SELECT books.get_bank_account_id(NULL, 'ANZ Cheque');
--
-- Dependencies
--   Tables    : bank.account
-- ============================================================
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