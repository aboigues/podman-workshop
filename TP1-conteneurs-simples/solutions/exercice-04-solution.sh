#!/bin/bash

# Solution de l'Exercice 4 : Mode interactif

echo "🖥️  Exercice 4 : Mode interactif"
echo ""

echo "📝 Étape 1 : Mode interactif"
echo ""
echo "Commande : podman run -it alpine /bin/sh"
echo ""
echo "Une fois dedans, essayez :"
echo "  whoami"
echo "  pwd"
echo "  ls /"
echo "  exit"
echo ""

echo "📦 Étape 3 : Test de podman exec..."
podman run -d --name exec-test nginx:latest
sleep 2
echo "✓ Conteneur créé"
echo ""

echo "🔧 Exécution d'une commande dans le conteneur :"
podman exec exec-test nginx -v
echo ""

echo "🧹 Nettoyage..."
podman rm -f exec-test >/dev/null 2>&1
echo "✓ Terminé"
