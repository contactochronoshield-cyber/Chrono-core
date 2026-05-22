# -*- coding: utf-8 -*-
import os
import time
import socket
import logging
from logging.handlers import RotatingFileHandler
import subprocess
from flask import Flask, jsonify, request, abort

app = Flask(__name__)
ACCESS_TOKEN = "CHRONO_SECURE_TOKEN_2026_XYZ" 
LOG_FILE = os.path.expanduser("~/chronoshield-core/cluster_activity.log")

log_handler = RotatingFileHandler(LOG_FILE, maxBytes=5*1024*1024, backupCount=3, encoding='utf-8')
log_handler.setFormatter(logging.Formatter('[%(asctime)s] [%(levelname)s] %(message)s', '%Y-%m-%d %H:%M:%S'))
logger = logging.getLogger("ChronoShieldLogger")
logger.setLevel(logging.INFO)
logger.addHandler(log_handler)

def verificar_token():
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        abort(401, description="Token ausente.")
    if auth_header.split(" ")[1] != ACCESS_TOKEN:
        abort(403, description="Token invalido.")

def obtener_metricas():
    cpu, ram = 0.0, 0.0
    try:
        with open('/proc/stat', 'r') as f:
            line = f.readline().strip().split()[1:]
        campos = [float(x) for x in line]
        id_ant, tot_ant = campos[3], sum(campos)
        time.sleep(0.02)
        with open('/proc/stat', 'r') as f:
            line2 = f.readline().strip().split()[1:]
        campos2 = [float(x) for x in line2]
        dif_tot = sum(campos2) - tot_ant
        if dif_tot > 0:
            cpu = round((1.0 - ((campos2[3] - id_ant) / dif_tot)) * 100, 2)
    except: pass
    try:
        with open('/proc/meminfo', 'r') as f:
            for line in f:
                if 'MemTotal' in line: t = int(line.split()[1])
                elif 'MemAvailable' in line: a = int(line.split()[1])
        ram = round(((t - a) / t) * 100, 2)
    except: pass
    return cpu, ram

@app.route('/dashboard', methods=['GET'])
def dashboard():
    verificar_token()
    cpu, ram = obtener_metricas()
    return jsonify({"status": "ONLINE", "node_id": socket.gethostname().upper(), "role": "CORE-NODE", "cpu_usage": f"{cpu}%", "ram_usage": f"{ram}%"}), 200

@app.route('/update', methods=['POST'])
def update():
    verificar_token()
    cmd = "sleep 2 && git pull origin main && tmux kill-server 2>/dev/null; tmux new-session -d -s api 'python ~/chronoshield-core/server.py'"
    subprocess.Popen(cmd, shell=True)
    return jsonify({"status": "SUCCESS", "message": "Actualizacion OTA agendada."}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, threaded=True)
