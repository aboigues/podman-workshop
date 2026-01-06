#!/bin/bash

set -e

echo "🔨 Construction de l'image Python Flask"
echo ""

if [ ! -f "Dockerfile" ]; then
    echo "❌ Erreur : Le fichier Dockerfile n'existe pas !"
    echo ""
    echo "💡 Créez le fichier Dockerfile en vous basant sur Dockerfile.template"
    echo "   cp Dockerfile.template Dockerfile"
    echo "   nano Dockerfile"
    exit 1
fi

echo "📦 Construction de l'image mon-app-python:v1 ..."
podman build -t mon-app-python:v1 .

echo ""
echo "✅ Image construite avec succès !"
echo ""
echo "Pour tester :"
echo "  podman run -d --name test-python -p 5000:5000 mon-app-python:v1"
echo "  curl http://localhost:5000"
