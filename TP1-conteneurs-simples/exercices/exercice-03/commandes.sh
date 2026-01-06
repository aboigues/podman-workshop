#!/bin/bash

# Exercice 3 : Gérer le cycle de vie des conteneurs

set -e

echo "🔄 Exercice 3 : Cycle de vie des conteneurs"
echo ""

# Étape 1 : Créer un conteneur
echo "📦 Étape 1 : Création du conteneur..."
podman run ___ --name ___ -p ___:80 nginx:latest
echo "✓ Conteneur créé et démarré"
echo ""

# Vérifier qu'il tourne
echo "✓ Vérification : le conteneur est bien en cours d'exécution"
podman ps | grep lifecycle-test
sleep 2
echo ""

# Étape 2 : Arrêter le conteneur
echo "⏸️  Étape 2 : Arrêt du conteneur..."
podman ___ lifecycle-test
echo "✓ Conteneur arrêté"
echo ""

# Étape 3 : Lister tous les conteneurs
echo "📋 Étape 3 : Liste de tous les conteneurs (y compris arrêtés)..."
podman ps ___
echo ""

# Étape 4 : Redémarrer le conteneur
echo "▶️  Étape 4 : Redémarrage du conteneur..."
podman ___ lifecycle-test
echo "✓ Conteneur redémarré"
sleep 2
echo ""

# Vérifier qu'il tourne à nouveau
echo "✓ Vérification : le conteneur tourne à nouveau"
podman ps | grep lifecycle-test
echo ""

# Étape 5 : Supprimer le conteneur (force)
echo "🗑️  Étape 5 : Suppression du conteneur..."
podman rm ___ lifecycle-test
echo "✓ Conteneur supprimé"
echo ""

echo "============================================================"
echo "✨ Exercice terminé ! Lancez ./validation.sh pour valider."
echo "============================================================"
