#!/usr/bin/env python3
from flask import Flask, jsonify, render_template_string
import socket
import os

app = Flask(__name__)

HTML = '''
<!DOCTYPE html>
<html>
<head>
    <title>Podman TP2 - Python App</title>
    <style>
        body { font-family: Arial; margin: 40px; background: #f0f0f0; }
        .container { background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; }
        .info { background: #e3f2fd; padding: 15px; margin: 10px 0; }
        .endpoint { background: #f5f5f5; padding: 10px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Podman Workshop - Python App</h1>
        <div class="info">
            <p><strong>Container:</strong> {{ hostname }}</p>
            <p><strong>Python:</strong> {{ python_version }}</p>
        </div>
        <h2>Endpoints disponibles:</h2>
        <div class="endpoint"><a href="/">GET /</a> - Page principale</div>
        <div class="endpoint"><a href="/api/info">GET /api/info</a> - Info JSON</div>
        <div class="endpoint"><a href="/api/health">GET /api/health</a> - Health check</div>
    </div>
</body>
</html>
'''

@app.route('/')
def home():
    return render_template_string(
        HTML,
        hostname=socket.gethostname(),
        python_version=os.sys.version.split()[0]
    )

@app.route('/api/info')
def info():
    return jsonify({
        'app': 'podman-workshop-tp2',
        'version': '1.0.0',
        'hostname': socket.gethostname(),
        'python': os.sys.version.split()[0]
    })

@app.route('/api/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
