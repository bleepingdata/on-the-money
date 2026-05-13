DROP FUNCTION IF EXISTS books.last_day(date);

CREATE OR REPLACE FUNCTION books.last_day(date)
RETURNS date AS
$$
  SELECT (date_trunc('month', $1) + interval '1 month - 1 day')::date;
$$ LANGUAGE 'sql' IMMUTABLE STRICT;