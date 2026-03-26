drop function if exists books.get_accounts;

create or replace function books.get_accounts(s_account_type varchar(50) default null)
returns table (
    account_id int,
    account_code char(10),
    description varchar(50)
)
as $$
begin
    return query
    select a.account_id,
        a.account_code,
        a.description
    from books.account a
        inner join books.account_type at on a.account_type_id = at.account_type_id
    where (s_account_type is null or at.account_type = s_account_type)
    order by a.account_code;
end;
$$ language plpgsql;