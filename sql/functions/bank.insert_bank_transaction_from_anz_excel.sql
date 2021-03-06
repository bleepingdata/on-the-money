drop
	function if exists bank.insert_bank_transaction_from_anz_excel;

create or replace function bank.insert_bank_transaction_from_anz_excel ( s_bank_account_number varchar(56) = null,
s_bank_account_friendly_name varchar(256) = null ) 
returns int8 as $$ 
declare n_bank_account_id int;
n_import_identifier int8;
begin

 select
	a.bank_account_id into
		n_bank_account_id
	from
		bank.account a
	where
		a.external_unique_identifier = coalesce( rtrim(s_bank_account_number),
		a.external_unique_identifier )
		and a.external_friendly_name = coalesce( rtrim(s_bank_account_friendly_name),
		a.external_friendly_name )
		and ( s_bank_account_number is not null
		or s_bank_account_friendly_name is not null );

if n_bank_account_id is null then raise exception 'Nonexistent s_bank_account_number or s_bank_account_friendly_name --> %, %',
s_bank_account_number,
s_bank_account_friendly_name
	using HINT = 'Please check incoming parameters for s_bank_account_number and s_bank_account_friendly_name';
end if;

select
	nextval('bank.import_identifier') into
		n_import_identifier;

-- remove any existing bank transactions, based on transaction and processed_dates matching in the imported data
with distinct_loaded_dates as (
select
	cast( a."Transaction Date" as date ) as transaction_date,
	cast( a."Processed Date" as date ) as processed_date
from
	load.anz_excel a ) delete
from
	bank.transaction t
		using distinct_loaded_dates
		where
			distinct_loaded_dates.transaction_date = t.transaction_date
			and distinct_loaded_dates.processed_date = t.processed_date
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
		balance,
		other_party_bank_account_number,
		type,
		details,
		particulars,
		code,
		reference ) select
			a.bank_account_friendly_name,
			a.bank_account_number,
			n_bank_account_id,
			n_import_identifier,
			now(),
			cast( a."Transaction Date" as date ),
			cast ( a."Processed Date" as date ),
			cast( a."Amount" as money ),
			cast( a."Balance" as money ),
			"To/From Account Number",
			a."Type",
			a."Details",
			a."Particulars",
			a."Code",
			a."Reference"
		from
			load.anz_excel a;

return n_import_identifier;
end;

$$ language plpgsql;