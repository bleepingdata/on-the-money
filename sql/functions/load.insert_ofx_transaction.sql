DROP FUNCTION IF EXISTS load.insert_ofx_transaction;

-- ============================================================
-- Function : load.insert_ofx_transaction(int4, date, int4, varchar,
--              varchar, varchar, varchar, varchar, date, numeric,
--              varchar, varchar, varchar)
-- ============================================================
-- Purpose  : Inserts a single OFX transaction record into the load.ofx
--            staging table ready for subsequent import processing.
--
-- Parameters
--   n_bank_account_id  (int4)          : ID of the bank account the transaction belongs to.
--   dt_dtserver        (date)          : Server date from the OFX file header.
--   n_tranuid          (int4)          : Transaction unique identifier from the OFX file.
--   s_bankid           (varchar(50))   : Bank routing or BIC identifier.
--   s_branchid         (varchar(50))   : Branch identifier.
--   s_acctid           (varchar(50))   : Account number as recorded in the OFX file.
--   s_accttype         (varchar(50))   : Account type (e.g. CHECKING, SAVINGS).
--   s_trntype          (varchar(50))   : Transaction type (e.g. DEBIT, CREDIT, INT).
--   dt_dtposted        (date)          : Date the transaction was posted.
--   n_trnamt           (numeric(16,2)) : Transaction amount; negative for debits.
--   n_fitid            (varchar(50))   : Financial institution transaction ID.
--   s_name             (varchar(50))   : Payee or transaction name.
--   s_memo             (varchar(255))  : Additional memo or description from the OFX file.
--
-- Returns  : void
--
-- Usage
--   PERFORM load.insert_ofx_transaction(
--     1, '2026-01-15', 100001, 'ANZ', '010101',
--     '01-0101-0101010-00', 'CHECKING', 'DEBIT',
--     '2026-01-15', -42.50, '20260115-100001',
--     'COUNTDOWN', 'Grocery purchase');
--
-- Dependencies
--   Tables    : load.ofx
--   Functions : (none)
-- ============================================================
CREATE OR REPLACE FUNCTION load.insert_ofx_transaction ( n_bank_account_id int4,
dt_dtserver date = NULL,
n_tranuid int4 = NULL,
s_bankid varchar(50) = NULL,
s_branchid varchar(50) = NULL,
s_acctid varchar(50) = NULL,
s_accttype varchar(50) = NULL,
s_trntype varchar(50) = NULL,
dt_dtposted date = NULL,
n_trnamt numeric(16,2) = NULL,
n_fitid varchar(50) = NULL,
s_name varchar(50) = NULL,
s_memo varchar(255) = NULL) RETURNS void AS $$
BEGIN
INSERT INTO
		load.ofx (bank_account_id,
		dtserver,
		tranuid,
		bankid,
		branchid,
		acctid,
		accttype,
		trntype,
		dtposted,
		trnamt,
		fitid,
		name,
		memo)
	VALUES (n_bank_account_id,
	dt_dtserver,
	n_tranuid,
	s_bankid,
	s_branchid,
	s_acctid,
	s_accttype,
	s_trntype,
	dt_dtposted,
	n_trnamt,
	n_fitid,
	s_name,
	s_memo);
END;

$$ LANGUAGE plpgsql;