create or replace function books.last_day(date)
returns date as
$$
  select (date_trunc('month', $1) + interval '1 month - 1 day')::date;
$$ language 'sql' immutable strict;