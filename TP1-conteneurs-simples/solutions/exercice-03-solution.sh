#!/bin/bash

# Solution de l'Exercice 3 : Cycle de vie

set -e

echo "🔄 Exercice 3 : Cycle de vie des conteneurs"
echo ""

echo "📦 Étape 1 : Création du conteneur..."
podman run -d --name lifecycle-test -p 8888:80 nginx:latest
echo "✓ Conteneur créé !"
sleep 2
echo ""

echo "⏸️  Étape 2 : Arrêt du conteneur..."
podman stop lifecycle-test
echo "✓ Conteneur arrêté"
echo ""

echo "📋 Étape 3 : Liste de tous les conteneurs..."
podman ps -a
echo ""

echo "▶️  Étape 4 : Redémarrage..."
podman start lifecycle-test
echo "✓ Conteneur redémarré"
sleep 2
echo ""

echo "🗑️  Étape 5 : Suppression..."
podman rm -f lifecycle-test
echo "✓ Conteneur supprimé"
echo ""

echo "============================================================"
echo "✨ Exercice terminé !"
echo "============================================================"
