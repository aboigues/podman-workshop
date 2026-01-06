#!/bin/bash

echo "🖥️  Exercice 4 : Mode interactif"
echo ""

# Étape 1 : Mode interactif (sera fait manuellement)
echo "📝 Étape 1 : Lancez cette commande pour entrer dans un conteneur interactif :"
echo ""
echo "   podman run ___ alpine ___"
echo ""
echo "   Complétez avec :"
echo "   - Options pour mode interactif + tty : -it"
echo "   - Commande shell : /bin/sh"
echo ""
echo "   Une fois dedans, explorez avec : whoami, pwd, ls /, exit"
echo ""

# Étape 3 : Exec dans un conteneur existant
echo "📦 Étape 3 : Créer un conteneur pour tester exec..."
podman run -d --name exec-test nginx:latest
sleep 2
echo "✓ Conteneur exec-test créé"
echo ""

echo "🔧 Exécutez une commande dans le conteneur avec podman exec :"
echo "   podman ___ exec-test nginx -v"
echo ""
echo "   Cette commande affiche la version de nginx installée dans le conteneur."
echo ""

# Nettoyage
echo "🧹 Nettoyage..."
podman rm -f exec-test >/dev/null 2>&1
echo "✓ Terminé"
