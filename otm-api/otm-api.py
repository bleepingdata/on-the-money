#!/usr/bin/env python
# encoding: utf-8
"""
Script: otm-api.py
Purpose: A basic Flask API to trigger database summary calculations and potentially serve data.
"""
import json
import hashlib
import hmac
import logging
import os
import secrets
from datetime import timedelta
from typing import Optional

from flask import Flask, request, jsonify, render_template, Response, redirect, session, url_for, make_response
import psycopg2

# connection_strings.py is git-ignored to protect credentials; must define all five variables below
from connection_strings import s_databasename, s_username, s_password, s_host, n_port
import otm_summary

logger = logging.getLogger(__name__)

app = Flask(__name__)
api_password = os.environ.get('OTM_API_PASSWORD')
secret_key = os.environ.get('OTM_API_SECRET_KEY')
if not api_password or not secret_key or len(secret_key) < 32:
    raise RuntimeError('Set OTM_API_PASSWORD and OTM_API_SECRET_KEY (at least 32 characters) before starting the API')
app.config.update(
    SECRET_KEY=secret_key,
    PERMANENT_SESSION_LIFETIME=timedelta(hours=8),
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    SESSION_COOKIE_SECURE=os.environ.get('OTM_API_SECURE_COOKIE') == 'true',
)

# Establish the database connection globally for the app usage
try:
    conn = psycopg2.connect(database=s_databasename, user=s_username, password=s_password, host=s_host, port=n_port)
except (Exception, psycopg2.Error) as error:
    logger.critical("Error while connecting to PostgreSQL: %s", error)


@app.before_request
def require_login() -> Optional[Response]:
    """
    Require a session and CSRF token before accessing financial resources.

    Args:
        None

    Returns:
        A redirect or JSON error for unauthorized requests; None otherwise.

    Raises:
        None

    Example:
        >>> # Unauthenticated GET /accounts/bank returns 401.
    """
    if request.endpoint in ('login', 'static'):
        return None
    if not session.get('authenticated'):
        logger.warning("Unauthenticated request to %s", request.path)
        if request.endpoint in ('index', 'rules_page', 'new_rule_page'):
            return redirect(url_for('login'))
        return make_response(jsonify({'error': 'Authentication required'}), 401)
    if request.method not in ('GET', 'HEAD', 'OPTIONS'):
        token = request.headers.get('X-CSRF-Token', '')
        if not hmac.compare_digest(token, session.get('csrf_token', '')):
            logger.warning("Invalid CSRF token for %s", request.path)
            return make_response(jsonify({'error': 'Invalid CSRF token'}), 403)
    return None


@app.route('/login', methods=['GET', 'POST'])
def login() -> Response:
    """
    GET /login renders the sign-in page; POST /login authenticates a password.

    Args:
        None (POST body: JSON object with a password)

    Returns:
        200: HTML page or JSON message and CSRF token.
        400: Missing or invalid JSON body.
        401: Incorrect password.

    Raises:
        None

    Example:
        >>> # POST /login with {"password": "your configured password"}
    """
    if request.method == 'GET':
        return render_template('login.html')
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or not isinstance(data.get('password'), str):
        logger.warning("Invalid login request")
        return make_response(jsonify({'error': 'Password required'}), 400)
    supplied = hashlib.sha256(data['password'].encode('utf-8')).digest()
    expected = hashlib.sha256(api_password.encode('utf-8')).digest()
    if not hmac.compare_digest(supplied, expected):
        logger.warning("Incorrect API password")
        return make_response(jsonify({'error': 'Invalid password'}), 401)
    session.clear()
    session.permanent = True
    session['authenticated'] = True
    session['csrf_token'] = secrets.token_urlsafe(32)
    return jsonify({'message': 'Logged in', 'csrf_token': session['csrf_token']})


@app.route('/logout', methods=['POST'])
def logout() -> Response:
    """
    POST /logout clears the current session.

    Args:
        None

    Returns:
        200: JSON confirmation.

    Raises:
        None

    Example:
        >>> # POST /logout with the session CSRF header.
    """
    session.clear()
    return jsonify({'message': 'Logged out'})

# ---------------------------------------------------------
# ROUTES
# ---------------------------------------------------------
@app.route('/')
def index() -> Response:
    """
    GET /

    Renders the summary page: bank account balances and data freshness date.

    Args:
        None

    Returns:
        200: HTML summary page.

    Raises:
        None

    Example:
        >>> # Browser navigation to http://localhost:5000/
    """
    return render_template('index.html')

@app.route('/summary/populate', methods=['PUT'])
def get_summary() -> Response:
    """
    PUT /summary/populate

    Triggers recalculation of the fact.account_summary_by_month table by calling
    the populate_account_summary_by_month stored procedure.

    Args:
        None

    Returns:
        200: Confirmation string on success.

    Raises:
        None

    Example:
        >>> # PUT http://localhost:5000/summary/populate
    """
    otm_summary.populate_account_summary_by_month(conn)
    return 'Population of fact.account_summary_by_month complete'

@app.route('/rules/expense', methods=['POST'])
def add_expense_rule() -> Response:
    """
    POST /rules/expense

    Creates a new expense import rule by calling bank.insert_import_rule_gl_rules_expense.
    Accepts a JSON body containing the rule fields (see stored procedure parameters).
    Empty strings in optional fields are normalised to None before the DB call.

    Args:
        None (body: JSON object with rule fields)

    Returns:
        200: { "message": "Rule added successfully" }
        500: { "error": str } — database or server error.

    Raises:
        Exception: Re-raised after rolling back the transaction.

    Example:
        >>> # POST http://localhost:5000/rules/expense
        >>> # Body: { "s_expense_account": "6100", "s_cash_account": "1010", ... }
    """
    try:
        data = request.get_json()
        
        # Extract parameters from JSON payload
        params = {
            's_expense_account': data.get('s_expense_account'),
            's_cash_account': data.get('s_cash_account'),
            'n_priority': data.get('n_priority', 0),
            's_bank_account': data.get('s_bank_account'),
            'b_is_deposit': data.get('b_is_deposit', False),
            's_type': data.get('s_type'),
            's_other_party_bank_account_number': data.get('s_other_party_bank_account_number'),
            's_details': data.get('s_details'),
            's_particulars': data.get('s_particulars'),
            's_code': data.get('s_code'),
            's_reference': data.get('s_reference'),
            's_ofx_name': data.get('s_ofx_name'),
            's_ofx_memo': data.get('s_ofx_memo'),
            's_wildcard_field': data.get('s_wildcard_field')
        }
        
        # Convert empty strings to None for optional fields (excluding boolean/int fields)
        for k, v in params.items():
            if v == "" and k not in ['b_is_deposit', 'n_priority']:
                params[k] = None
        
        cur = conn.cursor()
        # Use named parameters for clarity and robustness
        sql = """
            SELECT bank.insert_import_rule_gl_rules_expense(
                s_expense_account := %(s_expense_account)s::varchar,
                s_cash_account := %(s_cash_account)s::varchar,
                n_priority := %(n_priority)s::smallint,
                s_bank_account := %(s_bank_account)s::varchar,
                b_is_deposit := %(b_is_deposit)s::boolean,
                s_type := %(s_type)s::varchar,
                s_other_party_bank_account_number := %(s_other_party_bank_account_number)s::varchar,
                s_details := %(s_details)s::varchar,
                s_particulars := %(s_particulars)s::varchar,
                s_code := %(s_code)s::varchar,
                s_reference := %(s_reference)s::varchar,
                s_ofx_name := %(s_ofx_name)s::varchar,
                s_ofx_memo := %(s_ofx_memo)s::varchar,
                s_wildcard_field := %(s_wildcard_field)s::varchar
            )
        """
        cur.execute(sql, params)
        conn.commit()
        cur.close()
        
        return jsonify({'message': 'Rule added successfully'})
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500

# @app.route('/', methods=['GET'])
# def query_records():
#     name = request.args.get('name')
#     print (name)
#     with open('./tmp/data.txt', 'r') as f:
#         data = f.read()
#         records = json.loads(data)
#         for record in records:
#             if record['name'] == name:
#                 return jsonify(record)
#         return jsonify({'error': 'data not found'})

# @app.route('/', methods=['PUT'])
# def create_record():
#     record = json.loads(request.data)
#     with open('./tmp/data.txt', 'r') as f:
#         data = f.read()
#     if not data:
#         records = [record]
#     else:
#         records = json.loads(data)
#         records.append(record)
#     with open('./tmp/data.txt', 'w') as f:
#         f.write(json.dumps(records, indent=2))
#     return jsonify(record)

# @app.route('/', methods=['POST'])
# def update_record():
#     request_record = json.loads(request.data)
#     new_records = []
#     with open('./tmp/data.txt', 'r') as f:
#         data = f.read()
#         records = json.loads(data)
#     for r in records:
#         if r['name'] == request_record['name']:
#             r['email'] = request_record['email']
#         new_records.append(r)
#     with open('./tmp/data.txt', 'w') as f:
#         f.write(json.dumps(new_records, indent=2))
#     return jsonify(request_record)

# @app.route('/', methods=['DELETE'])
# def delte_record():
#     record = json.loads(request.data)
#     new_records = []
#     with open('./tmp/data.txt', 'r') as f:
#         data = f.read()
#         records = json.loads(data)
#         for r in records:
#             if r['name'] == record['name']:
#                 continue
#             new_records.append(r)
#     with open('./tmp/data.txt', 'w') as f:
#         f.write(json.dumps(new_records, indent=2))
#     return jsonify(record)

@app.route('/rules', methods=['GET'])
def rules_page() -> Response:
    """
    GET /rules

    Renders the import rules management page.

    Args:
        None

    Returns:
        200: HTML rules page.

    Raises:
        None

    Example:
        >>> # Browser navigation to http://localhost:5000/rules
    """
    return render_template('rules.html')

@app.route('/rules/new', methods=['GET'])
def new_rule_page() -> Response:
    """
    GET /rules/new

    Renders the page for adding an expense import rule.

    Args:
        None

    Returns:
        200: HTML add-rule page.

    Raises:
        None

    Example:
        >>> # Browser navigation to http://localhost:5000/rules/new
    """
    return render_template('new_rule.html')

@app.route('/rules/list', methods=['GET'])
def list_rules() -> Response:
    """
    GET /rules/list

    Returns all import rules from bank.get_import_rules as a JSON array.

    Args:
        None

    Returns:
        200: JSON array of import rule objects.
        500: { "error": str } — database error.

    Raises:
        Exception: Re-raised after returning a 500 response.

    Example:
        >>> # GET http://localhost:5000/rules/list
    """
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM bank.get_import_rules()")
        rows = cur.fetchall()
        cur.close()
        return jsonify([{
            'import_rule_id': row[0],
            'rule_type': row[1],
            'priority': row[2],
            'start_date': row[3].isoformat() if row[3] else None,
            'end_date': row[4].isoformat() if row[4] else None,
            'bank_account': row[5],
            'is_deposit': row[6],
            'transaction_type': row[7],
            'other_party_bank_account_number': row[8],
            'details': row[9],
            'particulars': row[10],
            'code': row[11],
            'reference': row[12],
            'ofx_name': row[13],
            'ofx_memo': row[14],
            'wildcard_field': row[15],
            'debit_account_1': row[16],
            'credit_account_1': row[17],
            'debit_account_2': row[18],
            'credit_account_2': row[19]
        } for row in rows])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/rules/<int:rule_id>', methods=['DELETE'])
def delete_rule(rule_id: int) -> Response:
    """
    DELETE /rules/{rule_id}

    Deletes an import rule by ID using bank.delete_import_rule.

    Args:
        rule_id (int): The primary key of the import rule to delete.

    Returns:
        200: { "message": "Rule deleted successfully" }
        500: { "error": str } — database error.

    Raises:
        Exception: Re-raised after rolling back the transaction.

    Example:
        >>> # DELETE http://localhost:5000/rules/42
    """
    try:
        cur = conn.cursor()
        cur.execute("SELECT bank.delete_import_rule(%s::int4)", (rule_id,))
        conn.commit()
        cur.close()
        return jsonify({'message': 'Rule deleted successfully'})
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/accounts/bank', methods=['GET'])
def get_bank_accounts() -> Response:
    """
    GET /accounts/bank

    Returns the list of bank account descriptions from bank.get_bank_account_descriptions.

    Args:
        None

    Returns:
        200: JSON array of bank account description strings.
        500: { "error": str } — database error.

    Raises:
        Exception: Re-raised after returning a 500 response.

    Example:
        >>> # GET http://localhost:5000/accounts/bank
    """
    try:
        cur = conn.cursor()
        cur.execute("select description from bank.get_bank_account_descriptions()")
        rows = cur.fetchall()
        cur.close()
        return jsonify([row[0] for row in rows])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/accounts/books', methods=['GET'])
def get_books_accounts() -> Response:
    """
    GET /accounts/books

    Returns chart-of-accounts entries from books.get_accounts, optionally filtered
    by account type via the account_type query parameter.

    Args:
        None (query param: account_type (str, optional) — filters accounts by type)

    Returns:
        200: JSON array of { account_id, account_code, description } objects.
        500: { "error": str } — database error.

    Raises:
        Exception: Re-raised after returning a 500 response.

    Example:
        >>> # GET http://localhost:5000/accounts/books?account_type=asset
    """
    try:
        account_type = request.args.get('account_type')
        cur = conn.cursor()
        # Use explicit casting as per AI_CODING_RULES.md
        cur.execute("SELECT account_id, account_code, description FROM books.get_accounts(%s::varchar)", (account_type,))
        rows = cur.fetchall()
        cur.close()
        
        # Return list of objects containing ID, Code, and Description
        return jsonify([{
            'account_id': row[0],
            'account_code': row[1].strip() if row[1] else None,
            'description': row[2]
        } for row in rows])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/accounts/bank/data-as-at', methods=['GET'])
def get_bank_data_as_at() -> Response:
    """
    GET /accounts/bank/data-as-at

    Returns the most recent bank transaction date, showing how up to date the
    imported data is, from bank.get_latest_transaction_date.

    Args:
        None

    Returns:
        200: { "latest_transaction_date": "YYYY-MM-DD" or null when no transactions exist }
        500: { "error": str } — database or server error.

    Raises:
        None

    Example:
        >>> # GET http://localhost:5000/accounts/bank/data-as-at
    """
    cur = None
    try:
        cur = conn.cursor()
        cur.execute("SELECT bank.get_latest_transaction_date()")
        latest = cur.fetchone()[0]
        return jsonify({'latest_transaction_date': latest.isoformat() if latest else None})
    except psycopg2.DatabaseError as e:
        conn.rollback()
        logger.error("Database error in get_bank_data_as_at: %s", e, exc_info=True)
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        logger.error("Unexpected error in get_bank_data_as_at: %s", e, exc_info=True)
        return jsonify({'error': str(e)}), 500
    finally:
        if cur:
            cur.close()

@app.route('/accounts/bank/balances', methods=['GET'])
def get_bank_account_balances() -> Response:
    """
    GET /accounts/bank/balances

    Returns each bank account with its current balance from
    bank.get_bank_accounts_with_balances. Closed accounts are excluded unless
    the include_closed query parameter is true.

    Args:
        None (query param: include_closed (bool, optional) — defaults to false)

    Returns:
        200: JSON array of { bank_account_id, description, bank_account_type, open_date,
             close_date, current_balance, last_transaction_date, transaction_count }.
        500: { "error": str } — database or server error.

    Raises:
        None

    Example:
        >>> # GET http://localhost:5000/accounts/bank/balances?include_closed=true
    """
    cur = None
    try:
        is_include_closed = request.args.get('include_closed', 'false').lower() == 'true'
        cur = conn.cursor()
        cur.execute(
            "SELECT bank_account_id, description, bank_account_type, open_date, close_date, "
            "current_balance, last_transaction_date, transaction_count "
            "FROM bank.get_bank_accounts_with_balances(%s::boolean)",
            (is_include_closed,)
        )
        rows = cur.fetchall()
        return jsonify([{
            'bank_account_id': row[0],
            'description': row[1],
            'bank_account_type': row[2],
            'open_date': row[3].isoformat() if row[3] else None,
            'close_date': row[4].isoformat() if row[4] else None,
            # numeric arrives as Decimal; JSON needs a float
            'current_balance': float(row[5]),
            'last_transaction_date': row[6].isoformat() if row[6] else None,
            'transaction_count': row[7]
        } for row in rows])
    except psycopg2.DatabaseError as e:
        conn.rollback()
        logger.error("Database error in get_bank_account_balances: %s", e, exc_info=True)
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        logger.error("Unexpected error in get_bank_account_balances: %s", e, exc_info=True)
        return jsonify({'error': str(e)}), 500
    finally:
        if cur:
            cur.close()

@app.route('/accounts/bank/summary', methods=['GET'])
def get_bank_account_summary() -> Response:
    """
    GET /accounts/bank/summary

    Returns bank account totals grouped by account type from
    bank.get_bank_account_balance_summary.

    Args:
        None (query param: include_closed (bool, optional) — defaults to false)

    Returns:
        200: JSON array of { bank_account_type, account_count, total_balance }.
        500: { "error": str } — database or server error.

    Raises:
        None

    Example:
        >>> # GET http://localhost:5000/accounts/bank/summary
    """
    cur = None
    try:
        is_include_closed = request.args.get('include_closed', 'false').lower() == 'true'
        cur = conn.cursor()
        cur.execute(
            "SELECT bank_account_type, account_count, total_balance "
            "FROM bank.get_bank_account_balance_summary(%s::boolean)",
            (is_include_closed,)
        )
        rows = cur.fetchall()
        return jsonify([{
            'bank_account_type': row[0],
            'account_count': row[1],
            'total_balance': float(row[2])
        } for row in rows])
    except psycopg2.DatabaseError as e:
        conn.rollback()
        logger.error("Database error in get_bank_account_summary: %s", e, exc_info=True)
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        logger.error("Unexpected error in get_bank_account_summary: %s", e, exc_info=True)
        return jsonify({'error': str(e)}), 500
    finally:
        if cur:
            cur.close()

if __name__ == '__main__':
    app.run(host='127.0.0.1', debug=False)