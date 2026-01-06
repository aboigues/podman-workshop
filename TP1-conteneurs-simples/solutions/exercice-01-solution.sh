#!/bin/bash

# Solution complète de l'Exercice 1 : Lancer un conteneur nginx

set -e

echo "🚀 Exercice 1 : Lancer un conteneur nginx"
echo ""

# Étape 1 : Lancer le conteneur nginx
echo "📦 Étape 1 : Lancement du conteneur..."

podman run -d --name mon-nginx -p 8080:80 nginx:latest

echo "✓ Conteneur lancé !"
echo ""

# Étape 2 : Vérifier que le conteneur est en cours d'exécution
echo "🔍 Étape 2 : Vérification du statut..."

podman ps

echo ""

# Étape 3 : Tester le service HTTP
echo "🌐 Étape 3 : Test du service HTTP..."
echo "   URL: http://localhost:8080"
echo ""

sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
    echo "✅ Le service répond correctement !"
else
    echo "❌ Le service ne répond pas. Vérifiez vos commandes."
    exit 1
fi

echo ""
echo "============================================================"
echo "✨ Exercice terminé ! Lancez ./validation.sh pour valider."
echo "============================================================"
