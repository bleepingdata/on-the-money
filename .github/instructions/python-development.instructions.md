---
description: Code style, documentation, and exception-handling standards for Python development in the On The Money project. Apply when creating or editing any Python file.
applyTo: "**/*.py"
---

# On The Money — Python Development Standards

## Naming Conventions

- **Functions and variables**: `snake_case` — e.g. `calculate_balance`, `transaction_amount`
- **Constants**: `UPPER_SNAKE_CASE` — e.g. `MAX_RETRIES`, `DEFAULT_PORT`
- **Classes**: `PascalCase` — e.g. `BankImporter`, `TransactionProcessor`
- **Private methods and attributes**: prefix with `_` — e.g. `_validate_input`, `_build_query`
- **Boolean variables**: `is_`, `has_`, `should_` prefix — e.g. `is_active`, `has_errors`
- **Module-level logger**: always named `logger = logging.getLogger(__name__)`

## Imports

Order imports in three groups separated by a blank line:

```python
# 1. Standard library
import json
import logging
from datetime import datetime
from typing import Optional, List, Dict, Tuple

# 2. Third-party
import psycopg2
from flask import Flask, request, jsonify

# 3. Local / project
from connection_strings import s_databasename, s_username, s_password, s_host, n_port
```

Never use wildcard imports (`from module import *`).

## Documentation

### Functions

Every function must have a docstring. At minimum:
- A one-sentence summary ending with a period.
- An `Args` section (even if there are no args, write `None`).
- A `Returns` section.
- A `Raises` section listing exceptions the caller should expect.
- An `Example` block showing a realistic call.

For complex functions, add a description paragraph between the summary and `Args`.

```python
def calculate_balance(account_id: int, as_of_date: Optional[str] = None) -> float:
    """
    Calculate the running balance of a bank account.

    Sums all GL entries for the given account. When as_of_date is provided,
    only entries on or before that date are included, enabling historical
    balance queries.

    Args:
        account_id (int): Primary key of the bank account.
        as_of_date (str, optional): ISO date string 'YYYY-MM-DD'. Defaults to
            today when omitted.

    Returns:
        float: Account balance rounded to two decimal places.

    Raises:
        ValueError: If account_id is not a positive integer.
        ValueError: If as_of_date is not a valid ISO date string.
        DatabaseError: If the database query fails.

    Example:
        >>> balance = calculate_balance(42)
        >>> print(f"Balance: ${balance:.2f}")
        Balance: $1234.56

        >>> historical = calculate_balance(42, "2026-01-01")
    """
```

### Classes

Class docstrings must describe the class purpose, list public attributes, and include a usage example:

```python
class BankImporter:
    """
    Imports bank transactions from formatted Excel or OFX files.

    Parses the source file, validates each row, inserts records into the
    staging table, and triggers the downstream stored procedures to apply
    import rules and generate GL entries.

    Attributes:
        connection: Active psycopg2 database connection.
        logger (logging.Logger): Module-level logger.

    Example:
        >>> importer = BankImporter(connection)
        >>> result = importer.import_file("transactions.xlsx")
        >>> print(f"Imported {result['count']} transactions")
    """
```

### Inline Comments

Add inline comments to explain *why*, not *what*:

```python
# Sort descending so higher-priority rules are evaluated first
sorted_rules = sorted(rules, key=lambda r: r["priority"], reverse=True)

# Round using ROUND_HALF_UP to match bank statement rounding behaviour
result = decimal_amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
```

## Exception Handling

### Rules

- Wrap **all** external operations in `try/except`: database calls, file I/O, HTTP requests.
- Catch **specific** exceptions first, then broad `Exception` as a final fallback.
- Never swallow exceptions silently — always log or re-raise.
- Include relevant context in every error message (IDs, file paths, received values).
- Use `logging` for all error reporting — never `print`.

### Pattern

```python
def fetch_transactions(account_id: int) -> List[Dict]:
    """Fetch all transactions for an account."""
    cursor = None
    try:
        cursor = connection.cursor()
        cursor.execute(
            "SELECT * FROM bank.transaction WHERE bank_account_id = %s::int",
            (account_id,)
        )
        columns = [desc[0] for desc in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]

    except psycopg2.DatabaseError as e:
        logger.error("Database error fetching transactions for account %s: %s", account_id, e)
        raise

    except Exception as e:
        logger.error("Unexpected error in fetch_transactions (account_id=%s): %s", account_id, e, exc_info=True)
        raise

    finally:
        if cursor:
            cursor.close()
```

### Flask Routes

Every route must:
1. Validate inputs before touching the database.
2. Catch exceptions by type and return the appropriate HTTP status.
3. Log warnings for client errors (4xx) and errors for server failures (5xx).

```python
@app.route("/api/accounts/<int:account_id>/balance", methods=["GET"])
def get_account_balance(account_id: int):
    """
    GET /api/accounts/{account_id}/balance

    Returns the current balance for a bank account.

    Returns:
        200: { "account_id": int, "balance": float }
        400: { "error": str } — invalid input
        404: { "error": str } — account not found
        500: { "error": str } — server failure
    """
    try:
        if account_id <= 0:
            return jsonify({"error": "account_id must be a positive integer"}), 400

        balance = calculate_balance(account_id)

        if balance is None:
            logger.warning("Account not found: %s", account_id)
            return jsonify({"error": f"Account {account_id} not found"}), 404

        return jsonify({"account_id": account_id, "balance": round(balance, 2)}), 200

    except ValueError as e:
        logger.warning("Validation error for account %s: %s", account_id, e)
        return jsonify({"error": str(e)}), 400

    except psycopg2.DatabaseError as e:
        logger.error("Database error for account %s: %s", account_id, e)
        return jsonify({"error": "Database error"}), 500

    except Exception as e:
        logger.error("Unexpected error in get_account_balance (account_id=%s): %s", account_id, e, exc_info=True)
        return jsonify({"error": "Internal server error"}), 500
```

## Database Queries

Always use explicit PostgreSQL type casts when passing parameters to stored procedures via psycopg2. This prevents parameters being treated as `unknown` type:

```python
# Correct — explicit casts
cursor.execute(
    "SELECT bank.insert_transaction(%s::int, %s::numeric, %s::varchar)",
    (account_id, amount, description)
)

# Wrong — no casts
cursor.execute(
    "SELECT bank.insert_transaction(%s, %s, %s)",
    (account_id, amount, description)
)
```

When passing many named parameters to a stored procedure, use a dictionary for clarity:

```python
params = {
    "account_id": account_id,
    "amount": amount,
    "description": description,
}
sql = """
    SELECT bank.insert_transaction(
        account_id := %(account_id)s::int,
        amount     := %(amount)s::numeric,
        description := %(description)s::varchar
    )
"""
cursor.execute(sql, params)
```

## Input Validation

Validate user-supplied input at the boundary (route handler or script entry point) before it reaches business logic or the database:

```python
def validate_amount(raw: str) -> float:
    """
    Parse and validate a transaction amount string.

    Args:
        raw (str): Raw amount value from user input.

    Returns:
        float: Validated positive amount.

    Raises:
        ValueError: If the value cannot be parsed or is not positive.

    Example:
        >>> validate_amount("123.45")
        123.45
    """
    try:
        value = float(str(raw).strip())
    except (ValueError, TypeError) as e:
        raise ValueError(f"Amount must be a number, received: '{raw}'") from e

    if value <= 0:
        raise ValueError(f"Amount must be positive, received: {value}")

    return value
```

## Logging

- Set up a module-level logger — never use `print` in production code.
- Use `%s` style formatting in log calls (not f-strings) so the message is only formatted when actually logged.
- Include `exc_info=True` on `logger.error` calls inside except blocks to capture the full traceback.

```python
import logging

logger = logging.getLogger(__name__)

# DEBUG  — step-by-step detail useful during development
logger.debug("Processing transaction %s for account %s", transaction_id, account_id)

# INFO   — normal milestones
logger.info("Import complete: %s transactions inserted", count)

# WARNING — unexpected but recoverable
logger.warning("Rule %s produced no matches for transaction %s", rule_id, transaction_id)

# ERROR  — operation failed; include context and exc_info
logger.error("Failed to insert transaction %s: %s", transaction_id, e, exc_info=True)
```

## Type Hints

All function parameters and return types must be annotated:

```python
from typing import Optional, List, Dict, Tuple

def import_file(file_path: str, account_id: int, dry_run: bool = False) -> Dict[str, int]:
    ...

def get_rules(account_id: int) -> List[Dict]:
    ...

def find_account(name: str) -> Optional[int]:
    ...
```

## Review Checklist

Before committing any Python file:

- [ ] Every function has a docstring with: summary, Args, Returns, Raises, Example
- [ ] Complex functions have inline comments explaining non-obvious logic
- [ ] All external operations (DB, file I/O) wrapped in `try/except`
- [ ] Specific exceptions caught before broad `Exception`
- [ ] `logging` used throughout — no `print` statements
- [ ] `exc_info=True` included on `logger.error` inside except blocks
- [ ] Type hints on all function parameters and return types
- [ ] User input validated before reaching business logic or DB calls
- [ ] PostgreSQL stored procedure calls use explicit type casts (`%s::int`, `%s::varchar`, etc.)
- [ ] No wildcard imports (`from module import *`)
- [ ] Flask routes return appropriate HTTP status codes (400 / 404 / 500)
- [ ] New or modified routes have a test in `test/test-api.ps1` (see `api-development.instructions.md`)
