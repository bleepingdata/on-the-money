DROP FUNCTION IF EXISTS load.insert_ofx_transaction;

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