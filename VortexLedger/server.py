from flask import Flask, jsonify, request
import os

app = Flask(__name__, static_folder='public', static_url_path='')

LEDGER_DB = {
    "daniel_node": 100000.0,
    "henry_node": 50000.0
}

@app.route('/')
def home():
    return app.send_static_file('index.html')

@app.route('/api/v1/send', methods=['POST'])
def send_transaction():
    data = request.get_json() or {}
    sender = data.get('sender')
    receiver = data.get('receiver')
    amount = data.get('amount', 0)
    
    if not sender or not receiver or amount <= 0:
        return jsonify({"status": "error", "message": "Parámetros inválidos"}), 400
        
    if sender not in LEDGER_DB or LEDGER_DB[sender] < amount:
        return jsonify({"status": "error", "message": "Fondos insuficientes o cuenta inexistente"}), 400

    if receiver not in LEDGER_DB:
        LEDGER_DB[receiver] = 0.0
        
    LEDGER_DB[sender] -= amount
    LEDGER_DB[receiver] += amount
    
    return jsonify({
        "status": "success", 
        "message": f"Transferencia exitosa. Nuevo saldo sender: {LEDGER_DB[sender]}"
    }), 200

@app.route('/api/v1/admin/mint', methods=['POST'])
def admin_mint():
    data = request.get_json() or {}
    alias = data.get('alias')
    amount = data.get('amount', 0)
    token = data.get('token')
    
    if token != "VORTEX_CEO_2026":
        return jsonify({"status": "error", "message": "Privilegios insuficientes. Token inválido."}), 403
        
    if not alias or amount <= 0:
        return jsonify({"status": "error", "message": "Datos de acuñación inválidos"}), 400
        
    if alias not in LEDGER_DB:
        LEDGER_DB[alias] = 0.0
        
    LEDGER_DB[alias] += amount
    return jsonify({
        "status": "success", 
        "message": f"Acuñación completada. Respaldo físico asignado a {alias}. Nuevo saldo: {LEDGER_DB[alias]}"
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
