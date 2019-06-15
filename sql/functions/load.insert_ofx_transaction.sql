drop
	function if exists load.insert_ofx_transaction;

create
or replace
function load.insert_ofx_transaction ( n_bank_account_id int4,
dt_dtserver date = null,
n_tranuid int4 = null,
s_bankid varchar(50) = null,
s_branchid varchar(50) = null,
s_acctid varchar(50) = null,
s_accttype varchar(50) = null,
dt_dtstart date = null,
dt_dtend date = null,
s_trntype varchar(50) = null,
dt_dtposted date = null,
n_trnamt numeric(16,2) = null,
n_fitid int4 = null,
s_name varchar(50) = null,
s_memo varchar(255) = null) returns void as $$
begin
insert
	into
		load.ofx (bank_account_id,
		dtserver,
		tranuid,
		bankid,
		branchid,
		acctid,
		accttype,
		dtstart,
		dtend,
		trntype,
		dtposted,
		trnamt,
		fitid,
		name,
		memo)
	values (n_bank_account_id,
	dt_dtserver,
	n_tranuid,
	s_bankid,
	s_branchid,
	s_acctid,
	s_accttype,
	dt_dtstart,
	dt_dtend,
	s_trntype,
	dt_dtposted,
	n_trnamt,
	n_fitid,
	s_name,
	s_memo);
end;

$$ language plpgsql;