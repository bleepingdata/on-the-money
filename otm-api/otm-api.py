#!/usr/bin/env python
# encoding: utf-8
"""
Script: otm-api.py
Purpose: A basic Flask API to trigger database summary calculations and potentially serve data.
"""
import json
import logging

from flask import Flask, request, jsonify, render_template, Response
import psycopg2

# connection_strings.py is git-ignored to protect credentials; must define all five variables below
from connection_strings import s_databasename, s_username, s_password, s_host, n_port
import otm_summary

logger = logging.getLogger(__name__)

# Establish the database connection globally for the app usage
try:
    conn = psycopg2.connect(database=s_databasename, user=s_username, password=s_password, host=s_host, port=n_port)
except (Exception, psycopg2.Error) as error:
    logger.critical("Error while connecting to PostgreSQL: %s", error)

app = Flask(__name__)

# ---------------------------------------------------------
# ROUTES
# ---------------------------------------------------------
@app.route('/')
def index() -> Response:
    """
    GET /

    Renders the main application index page.

    Args:
        None

    Returns:
        200: HTML index page.

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

app.run(debug=True)