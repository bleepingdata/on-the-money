drop function if exists books.cleanstringmoney;

create or replace function books.cleanstringmoney(moneyasstring varchar(50))
returns money
as $$
declare
    amount money;
    workingstring varchar(50);
begin
    select rtrim($1) into workingstring;
    -- set workingstring = replace(workingstring, '$', '');
    -- set workingstring = replace(workingstring, ' ', '');

    -- select cast(workingstring as money) into amount;

    return amount;
end;
$$ language plpgsql;