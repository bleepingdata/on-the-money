DROP FUNCTION IF EXISTS bank.get_latest_transaction_date();

-- ============================================================
-- Function : bank.get_latest_transaction_date()
-- ============================================================
-- Purpose  : Returns the most recent transaction date across all bank
--            transactions, showing how up to date the imported data is.
--
-- Parameters
--   None
--
-- Returns  : date : Latest bank.transaction.transaction_date, NULL when
--                   no transactions have been imported.
--
-- Usage
--   SELECT bank.get_latest_transaction_date();
--
-- Dependencies
--   Tables    : bank.transaction
-- ============================================================
CREATE OR REPLACE FUNCTION bank.get_latest_transaction_date()
RETURNS date AS $$
DECLARE
    v_latest_date date;
BEGIN
    SELECT MAX(bt.transaction_date)
    INTO v_latest_date
    FROM bank.transaction AS bt;

    RETURN v_latest_date;
END;
$$ LANGUAGE plpgsql;
