---
description: Code style, documentation, and error-handling standards for PostgreSQL development in the On The Money project. Apply when creating or editing any SQL file.
applyTo: "sql/**,drop-scripts/**"
---

# On The Money — SQL Development Standards

## Naming Conventions

- **Parameters**: `snake_case` — e.g. `account_id`, `transaction_amount`, `is_deposit`
- **Local variables**: `snake_case` with a `v_` prefix — e.g. `v_balance`, `v_rule_count`
- **Constants**: `snake_case` with a `c_` prefix — e.g. `c_max_priority`
- **Tables and columns**: `snake_case` — e.g. `bank_account`, `processed_date`
- **Functions**: `schema.verb_object` format — e.g. `bank.insert_transaction`, `books.calculate_balance`
- **Views**: `snake_case` with a `_view` suffix — e.g. `bank.account_summary_view`
- **Schemas**: `snake_case`, short and descriptive — e.g. `bank`, `books`, `fact`

## SQL Formatting

- SQL **keywords** in `UPPERCASE`: `SELECT`, `FROM`, `WHERE`, `INSERT`, `UPDATE`, `WITH`, `RETURNS`
- Identifiers, column names, function names in `lowercase`
- Indent nested blocks and CTEs consistently (one tab or four spaces)
- Each column in a `SELECT` list on its own line
- Use explicit table aliases (`AS bt`) when joining multiple tables
- Always name columns explicitly — avoid `SELECT *`
- Use `COALESCE` to handle nullable values rather than leaving callers to deal with `NULL`

## File Structure

Each file must follow this order:

```sql
-- Drop the old version cleanly before recreating
DROP FUNCTION IF EXISTS schema.function_name(param_type, ...);

-- Header comment block (see Documentation below)

CREATE OR REPLACE FUNCTION schema.function_name(
    param_name param_type,
    ...
)
RETURNS return_type AS $$
DECLARE
    v_variable_name variable_type;
BEGIN
    -- body
END;
$$ LANGUAGE plpgsql;
```

## Documentation

Every function **must** have a header comment immediately before `CREATE OR REPLACE FUNCTION`:

```sql
-- ============================================================
-- Function : schema.function_name(param_type, ...)
-- ============================================================
-- Purpose  : One or two sentences describing what this function
--            does and why it exists.
--
-- Parameters
--   param_name  (param_type) : Description of the parameter.
--
-- Returns  : Description of the return value(s).
--
-- Usage
--   SELECT schema.function_name('value');
--   -- or for void functions:
--   PERFORM schema.function_name('value');
--
-- Dependencies
--   Tables    : schema.table_one, schema.table_two
--   Functions : schema.other_function
-- ============================================================
```

- **Usage example** is mandatory — show a realistic call, not a placeholder.
- **Dependencies** should list any tables or functions directly referenced.
- Add **inline comments** before any non-obvious block: CTEs, window functions, priority logic, date boundary checks.

## Error Handling

Use `RAISE EXCEPTION` with a descriptive message and a `HINT` where remediation is possible:

```sql
-- Validate the account exists before proceeding
IF NOT EXISTS (SELECT 1 FROM bank.bank_account WHERE bank_account_id = account_id) THEN
    RAISE EXCEPTION 'Bank account not found: %', account_id
        USING HINT = 'Check that the account exists in bank.bank_account';
END IF;

-- Validate required parameters
IF amount IS NULL OR amount = 0 THEN
    RAISE EXCEPTION 'amount must be non-null and non-zero, received: %', amount;
END IF;
```

Rules:
- Validate all required parameters at the **top** of the function body, before any DML.
- Include the **problematic value** in the message (`%` substitution) so errors are self-explanatory.
- Use `USING HINT` to suggest corrective action when the fix is not obvious.
- In loops, use a nested `BEGIN … EXCEPTION WHEN OTHERS THEN` block to capture per-row errors without aborting the whole batch.

## Common Patterns

### Single-value lookup

```sql
-- Retrieve the account balance, defaulting to 0 if no entries exist
SELECT COALESCE(SUM(amount), 0)
INTO v_balance
FROM books.gl_entry
WHERE account_id = account_id;
```

### CTE with window function for priority selection

```sql
-- Rank matched rules by priority, then by earliest start date as a tiebreaker
WITH ranked_matches AS (
    SELECT
        rule_id,
        transaction_id,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY priority DESC, start_date ASC, rule_id ASC
        ) AS rank
    FROM matched_rules
)
SELECT rule_id
FROM ranked_matches
WHERE rank = 1;
```

### Loop with per-row error capture

```sql
FOR v_row IN SELECT * FROM staging_table LOOP
    BEGIN
        -- Process each row individually so a single failure does not abort the batch
        PERFORM bank.process_transaction(v_row.transaction_id);
    EXCEPTION WHEN OTHERS THEN
        -- Log the error and continue with remaining rows
        INSERT INTO logs.import_error (transaction_id, error_message, logged_at)
        VALUES (v_row.transaction_id, SQLERRM, NOW());
    END;
END LOOP;
```

## Review Checklist

Before committing any SQL file:

- [ ] `DROP FUNCTION IF EXISTS` present before `CREATE OR REPLACE`
- [ ] Header comment block includes: Purpose, Parameters, Returns, Usage example, Dependencies
- [ ] All required parameters validated for `NULL` and invalid values at the top of the function
- [ ] Error messages include the problematic value and a `HINT` where appropriate
- [ ] SQL keywords uppercase; all identifiers lowercase `snake_case`
- [ ] Inline comments explain non-obvious blocks (CTEs, window functions, priority logic)
- [ ] `initialisation/database-init.ps1` updated (see `database-maintenance.instructions.md`)
- [ ] `drop-scripts/database/drop-functions.sql` updated (see `database-maintenance.instructions.md`)
