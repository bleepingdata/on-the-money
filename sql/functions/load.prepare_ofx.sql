drop function if exists load.prepare_ofx;

create or replace function load.prepare_ofx ( n_bank_account_id int4 = null ) returns void as $$
begin
	-- delete from load.ofx for this account id
	DELETE FROM load.ofx WHERE bank_account_id = n_bank_account_id;

return;
end;

$$ language plpgsql;