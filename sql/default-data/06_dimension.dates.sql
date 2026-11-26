insert into dimension.dates (datekey, year, month_number, month_text, month_year_text, month_year_date)
select d.date,
    date_part('year', d.date),
    date_part('month', d.date),
    to_char(d.date, 'Mon'),
    to_char(d.date, 'Mon YYYY'),
    (date_trunc('MONTH', d.date) + interval '1 MONTH - 1 day')::date
from generate_series('2016-01-01', '2050-01-01', '1 day'::interval) d
on conflict (datekey) do nothing;
