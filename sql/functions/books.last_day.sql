DROP FUNCTION IF EXISTS books.last_day(date);

-- ============================================================
-- Function : books.last_day(date)
-- ============================================================
-- Purpose  : Returns the last calendar day of the month for the given date.
--            This is an immutable SQL function suitable for use in indexes
--            and computed columns.
--
-- Parameters
--   d_input_date  (date) : Any date within the target month.
--
-- Returns  : date — the last day of the month (e.g. 2024-01-31 for any
--            date in January 2024).
--
-- Usage
--   SELECT books.last_day('2024-02-10');
--   -- Returns: 2024-02-29
--
-- Dependencies
--   Tables    : (none)
-- ============================================================
CREATE OR REPLACE FUNCTION books.last_day(date)
RETURNS date AS
$$
  SELECT (date_trunc('month', $1) + interval '1 month - 1 day')::date;
$$ LANGUAGE 'sql' IMMUTABLE STRICT;