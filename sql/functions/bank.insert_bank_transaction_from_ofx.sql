drop
	function if exists bank.insert_bank_transaction_from_ofx;

create or replace function bank.insert_bank_transaction_from_ofx ( n_bank_account_id int4 = null ) 
returns int8 as $$ 
declare n_import_identifier int8;
begin

select
	nextval('bank.import_identifier') into
		n_import_identifier;

with distinct_loaded_dates as (
select
	cast( a.dtposted as date ) as transaction_date
from
	load.ofx a
where a.bank_account_id = n_bank_account_id) delete
from
	bank.transaction t
		using distinct_loaded_dates
		where
			distinct_loaded_dates.transaction_date = t.transaction_date
			and t.bank_account_id = n_bank_account_id;

-- add to staging tables
 insert
	into
		bank.transaction ( bank_account_friendly_name,
		bank_account_number,
		bank_account_id,
		import_identifier,
		import_datetime,
		transaction_date,
		processed_date,
		amount,
		type,
		ofx_name,
		ofx_memo) select
			a.external_friendly_name,
			a.external_unique_identifier,
			a.account_id,
			n_import_identifier,
			now(),
			cast( o.dtposted as date ),
			cast ( o.dtposted as date ),
			cast( o.trnamt as money ),
			o.trntype,
			o.name,
			o.memo
		from
			load.ofx o
			INNER JOIN books.account a ON o.bank_account_id = a.account_id
		where o.bank_account_id=n_bank_account_id;

return n_import_identifier;
end;

$$ language plpgsql;