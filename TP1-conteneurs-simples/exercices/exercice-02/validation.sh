#!/bin/bash

# Script de validation pour l'exercice 2

set -e

# Charger les utilitaires de validation
source ../../../lib/validation-utils.sh

# Variables
CONTAINER_NAME="log-generator"

# Gestion des arguments
if [ "$1" == "--cleanup" ]; then
    cleanup_exercise "$CONTAINER_NAME"
    exit 0
fi

# En-tête
exercice_header "Validation Exercice 2: Consulter les logs"

# Compteurs
PASSED=0
TOTAL=3

# ============================================================
# Test 1 : Le conteneur existe et tourne
# ============================================================
info "Test 1/3 : Vérification du conteneur..."
if check_container_exists "$CONTAINER_NAME" && check_container_running "$CONTAINER_NAME"; then
    success "Le conteneur '$CONTAINER_NAME' existe et est en cours d'exécution"
    PASSED=$((PASSED + 1))
else
    error "Le conteneur '$CONTAINER_NAME' n'existe pas ou n'est pas en cours d'exécution"
    show_hint 1 "Vérifiez que vous avez bien exécuté ./commandes.sh"
    show_hint 2 "Le conteneur doit tourner en mode détaché avec -d"
fi
echo ""

# ============================================================
# Test 2 : Les logs contiennent des messages
# ============================================================
info "Test 2/3 : Vérification du contenu des logs..."
if check_container_running "$CONTAINER_NAME"; then
    # Vérifier que les logs contiennent bien des messages
    LOG_COUNT=$(podman logs "$CONTAINER_NAME" 2>/dev/null | wc -l)
    if [ "$LOG_COUNT" -gt 0 ]; then
        success "Le conteneur génère des logs ($LOG_COUNT lignes)"
        PASSED=$((PASSED + 1))
    else
        error "Aucun log trouvé dans le conteneur"
        show_hint 1 "Le conteneur doit exécuter une boucle qui génère des logs"
    fi
else
    error "Impossible de tester : le conteneur ne tourne pas"
fi
echo ""

# ============================================================
# Test 3 : Vérification du format des logs
# ============================================================
info "Test 3/3 : Vérification du format des logs..."
if check_container_running "$CONTAINER_NAME"; then
    # Vérifier que les logs contiennent la date et "Message de log"
    if check_logs_contain "$CONTAINER_NAME" "Message de log"; then
        success "Les logs ont le bon format"
        PASSED=$((PASSED + 1))
    else
        error "Le format des logs ne correspond pas à celui attendu"
        show_hint 1 "Les logs doivent contenir 'Message de log'"
    fi
else
    error "Impossible de tester : le conteneur ne tourne pas"
fi
echo ""

# ============================================================
# Affichage de la progression
# ============================================================
show_progress $PASSED $TOTAL
echo ""

# ============================================================
# Résultat final
# ============================================================
validate_exercise "Exercice 2" $PASSED $TOTAL

# Code de sortie
if [ $PASSED -eq $TOTAL ]; then
    echo ""
    info "💡 Commandes utiles pour les logs :"
    echo "   podman logs log-generator              # Tous les logs"
    echo "   podman logs --tail 20 log-generator    # 20 dernières lignes"
    echo "   podman logs -f log-generator           # Temps réel (Ctrl+C pour arrêter)"
    echo "   podman logs --since 30s log-generator  # Logs des 30 dernières secondes"
    echo ""
    info "🧹 Pour nettoyer : ./validation.sh --cleanup"
    echo ""
    exit 0
else
    echo ""
    warning "Consultez indices.md si besoin d'aide"
    echo ""
    exit 1
fi
