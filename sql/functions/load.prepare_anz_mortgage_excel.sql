drop function if exists load.prepare_anz_mortgage_excel;

create or replace function load.prepare_anz_mortgage_excel () returns void as $$
begin
-- truncate the table that will hold the imported data
 truncate
	table
		load.anz_mortgage_excel;

return;
end;

$$ language plpgsql;