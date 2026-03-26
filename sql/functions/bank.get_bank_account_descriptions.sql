create or replace function bank.get_bank_account_descriptions(b_include_closed boolean default false)
returns table (description varchar) as $$
begin
    return query
    select 
        a.description
    from 
        bank.account a
    where 
        (b_include_closed is true or a.close_date >= current_date)
    order by 
        a.description;
end;
$$ language plpgsql;