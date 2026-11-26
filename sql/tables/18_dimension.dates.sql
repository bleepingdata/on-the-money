create table if not exists dimension.dates
(
    datekey date not null unique,
    year int not null,
    month_number int not null,
    month_text varchar(10) not null,
    month_year_text varchar(12) not null,
    month_year_date date not null
);
