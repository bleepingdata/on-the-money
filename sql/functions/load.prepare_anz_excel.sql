drop function if exists load.prepare_anz_excel;

create or replace function load.prepare_anz_excel ( s_bank_account_number varchar(56) = null,
s_bank_account_friendly_name varchar(256) = null ) returns void as $$ declare n_account_id int;
begin
-- truncate the table that will hold the imported data
 truncate
	table
		load.anz_excel;

return;
end;

$$ language plpgsql;