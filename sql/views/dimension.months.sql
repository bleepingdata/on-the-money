create or replace view dimension.months
AS
select month_year_date as monthkey, year, month_number, month_text, month_year_text 
from dimension.dates 
group by month_year_date, year, month_number, month_text, month_year_text