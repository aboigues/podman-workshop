#!/bin/bash

# Solution de l'Exercice 2 : Consulter les logs

set -e

echo "📋 Exercice 2 : Consulter les logs"
echo ""

# Étape 1 : Créer le générateur de logs
echo "📦 Étape 1 : Création d'un générateur de logs..."
podman run -d --name log-generator busybox sh -c "while true; do echo \"[$(date)] Message de log - Compteur: \$RANDOM\"; sleep 1; done"
echo "✓ Générateur créé !"
echo ""

sleep 3

# Étape 2 : Afficher tous les logs
echo "📄 Étape 2 : Affichage de tous les logs..."
echo ""
podman logs log-generator
echo ""

# Étape 3 : Afficher les 5 dernières lignes
echo "📄 Étape 3 : Affichage des 5 dernières lignes..."
echo ""
podman logs --tail 5 log-generator
echo ""

# Étape 4 : Suivre en temps réel
echo "📡 Étape 4 : Suivi des logs en temps réel (5 secondes)..."
echo ""
timeout 5 podman logs -f log-generator || true
echo ""
echo ""

echo "============================================================"
echo "✨ Exercice terminé !"
echo "============================================================"
