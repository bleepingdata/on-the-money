#!/usr/bin/env python
# encoding: utf-8
import json
from flask import Flask, request, jsonify

#from otm-populate-account-summary-by-month.py import populate_account_summary

# # connection string file added to git ignore
# The file defines s_databasename, s_username, s_password, s_host, n_port
#from file connection_strings import connection_strings
s_databasename = 'otm-hill-ranger'
s_username = 'otmadmin'
s_password = 'lilian99'
s_host = 'localhost'
n_port = 5432

#conn = psycopg2.connect(database = s_databasename, user = s_username, password = s_password, host = s_host, port = n_port)

app = Flask(__name__)

# @app.route('/summary/', methods=['GET'])
# def get_summary():
#  #   populate_account_summary (conn)
#     return jsonify({'summary': 'todo'})

# @app.route('/summary/populate', methods=['POST'])
# def get_summary():
#     #python ..\..\on-the-money\otm-api\otm-populate-account-summary-by-month.py -db $dbname -u $username -p $password -host $hostname -port $port
#     return jsonify({'summary': 'todo'})

@app.route('/', methods=['GET'])
def query_records():
    name = request.args.get('name')
    print (name)
    with open('./tmp/data.txt', 'r') as f:
        data = f.read()
        records = json.loads(data)
        for record in records:
            if record['name'] == name:
                return jsonify(record)
        return jsonify({'error': 'data not found'})

@app.route('/', methods=['PUT'])
def create_record():
    record = json.loads(request.data)
    with open('./tmp/data.txt', 'r') as f:
        data = f.read()
    if not data:
        records = [record]
    else:
        records = json.loads(data)
        records.append(record)
    with open('./tmp/data.txt', 'w') as f:
        f.write(json.dumps(records, indent=2))
    return jsonify(record)

@app.route('/', methods=['POST'])
def update_record():
    request_record = json.loads(request.data)
    new_records = []
    with open('./tmp/data.txt', 'r') as f:
        data = f.read()
        records = json.loads(data)
    for r in records:
        if r['name'] == request_record['name']:
            r['email'] = request_record['email']
        new_records.append(r)
    with open('./tmp/data.txt', 'w') as f:
        f.write(json.dumps(new_records, indent=2))
    return jsonify(request_record)

@app.route('/', methods=['DELETE'])
def delte_record():
    record = json.loads(request.data)
    new_records = []
    with open('./tmp/data.txt', 'r') as f:
        data = f.read()
        records = json.loads(data)
        for r in records:
            if r['name'] == record['name']:
                continue
            new_records.append(r)
    with open('./tmp/data.txt', 'w') as f:
        f.write(json.dumps(new_records, indent=2))
    return jsonify(record)

app.run(debug=True)