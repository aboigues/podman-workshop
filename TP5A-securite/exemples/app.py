#!/usr/bin/env python3
"""
Application Flask simple pour démontrer les bonnes pratiques de sécurité.
Cette application est utilisée avec le Dockerfile-secure.
"""

from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    """Page d'accueil"""
    return jsonify({
        'status': 'running',
        'message': 'Application sécurisée - Mode non-root',
        'user': os.getenv('USER', 'unknown')
    })

@app.route('/health')
def health():
    """Endpoint de santé pour monitoring"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    # Écouter sur toutes les interfaces, port 5000
    # Debug désactivé pour la production
    app.run(host='0.0.0.0', port=5000, debug=False)
