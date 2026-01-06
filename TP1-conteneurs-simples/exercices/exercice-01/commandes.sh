#!/bin/bash

# Exercice 1 : Créer et lancer votre premier conteneur
# Complétez les commandes ci-dessous en remplaçant les ___ par les bonnes valeurs

set -e

echo "🚀 Exercice 1 : Lancer un conteneur nginx"
echo ""

# ============================================================
# Étape 1 : Lancer le conteneur nginx
# ============================================================
# Objectif : Créer un conteneur nginx qui :
#   - S'exécute en mode détaché (arrière-plan)
#   - Se nomme "mon-nginx"
#   - Mappe le port 8080 (hôte) → port 80 (conteneur)
#   - Utilise l'image "nginx:latest"
#
# Indice : podman run [OPTIONS] IMAGE
# Options à utiliser : -d, --name, -p

echo "📦 Étape 1 : Lancement du conteneur..."

podman run ___ --name ___ -p ___:___ ___

echo "✓ Conteneur lancé !"
echo ""

# ============================================================
# Étape 2 : Vérifier que le conteneur est en cours d'exécution
# ============================================================
# Objectif : Afficher la liste des conteneurs actifs
#
# Indice : Utilisez la commande pour lister les conteneurs running

echo "🔍 Étape 2 : Vérification du statut..."

podman ___

echo ""

# ============================================================
# Étape 3 : Tester le service HTTP
# ============================================================
# Objectif : Vérifier que nginx répond sur le port 8080
#
# Cette étape utilise curl (déjà installé)

echo "🌐 Étape 3 : Test du service HTTP..."
echo "   URL: http://localhost:8080"
echo ""

# Attendre que le service démarre (2 secondes)
sleep 2

# Tester la connexion HTTP
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
