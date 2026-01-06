#!/bin/bash

# Exercice 2 : Consulter les logs des conteneurs
# Complétez les commandes ci-dessous

set -e

echo "📋 Exercice 2 : Consulter les logs"
echo ""

# ============================================================
# Étape 1 : Créer un conteneur qui génère des logs
# ============================================================
echo "📦 Étape 1 : Création d'un générateur de logs..."

# TODO: Lancez un conteneur busybox nommé "log-generator" qui :
#   - Tourne en mode détaché (-d)
#   - Se nomme "log-generator" (--name)
#   - Exécute la boucle fournie (déjà écrite ci-dessous)

podman run ___ --name ___ busybox sh -c "while true; do echo \"[$(date)] Message de log - Compteur: \$RANDOM\"; sleep 1; done"

echo "✓ Générateur de logs créé !"
echo ""

# Attendre 3 secondes pour générer quelques logs
echo "⏳ Génération de quelques logs (3 secondes)..."
sleep 3
echo ""

# ============================================================
# Étape 2 : Afficher tous les logs
# ============================================================
echo "📄 Étape 2 : Affichage de tous les logs..."
echo ""

# TODO: Affichez tous les logs du conteneur "log-generator"
podman ___ log-generator

echo ""

# ============================================================
# Étape 3 : Afficher seulement les 5 dernières lignes
# ============================================================
echo "📄 Étape 3 : Affichage des 5 dernières lignes..."
echo ""

# TODO: Affichez les 5 dernières lignes de logs
# Indice : utilisez l'option --tail
podman logs --tail ___ log-generator

echo ""

# ============================================================
# Étape 4 : Suivre les logs en temps réel (démo)
# ============================================================
echo "📡 Étape 4 : Suivi des logs en temps réel..."
echo "   (Les logs vont défiler pendant 5 secondes, puis s'arrêter automatiquement)"
echo ""

# TODO: Suivez les logs en temps réel
# Indice : utilisez l'option -f (follow)
# Note : timeout arrête automatiquement après 5 secondes pour la démo
timeout 5 podman logs ___ log-generator || true

echo ""
echo ""

echo "============================================================"
echo "✨ Exercice terminé ! Lancez ./validation.sh pour valider."
echo "============================================================"
echo ""
echo "💡 Astuce : Dans un usage réel, utilisez Ctrl+C pour arrêter le mode follow"
