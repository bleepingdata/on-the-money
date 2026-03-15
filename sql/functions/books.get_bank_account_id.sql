drop
	function if exists books.get_bank_account_id;

create
or replace
function books.get_bank_account_id ( s_bank_account_number varchar(56) = null,
s_bank_account_friendly_name varchar(256) = null) returns int4 as $$ declare n_bank_account_id int4;
begin

	select  bank_account_id into n_bank_account_id
	from bank.account a 
	where 
		(s_bank_account_number is not null or s_bank_account_friendly_name is not null)
		and
		(
			(external_unique_identifier = s_bank_account_number or s_bank_account_number is null)
			and
			(external_friendly_name = s_bank_account_friendly_name or s_bank_account_friendly_name is null)
		)
	;

return n_bank_account_id;

end;

$$ language plpgsql;