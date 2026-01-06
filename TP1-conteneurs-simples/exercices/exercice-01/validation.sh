#!/bin/bash

# Script de validation pour l'exercice 1
# Vérifie que le conteneur nginx est correctement configuré

set -e

# Charger les utilitaires de validation
source ../../../lib/validation-utils.sh

# Variables
CONTAINER_NAME="mon-nginx"
EXPECTED_PORT="8080"
EXPECTED_URL="http://localhost:8080"

# Gestion des arguments
if [ "$1" == "--cleanup" ]; then
    cleanup_exercise "$CONTAINER_NAME"
    exit 0
fi

# En-tête
exercice_header "Validation Exercice 1: Lancer un conteneur"

# Compteurs pour la progression
PASSED=0
TOTAL=4

# ============================================================
# Test 1 : Le conteneur existe
# ============================================================
info "Test 1/4 : Vérification de l'existence du conteneur..."
if check_container_exists "$CONTAINER_NAME"; then
    success "Le conteneur '$CONTAINER_NAME' existe"
    PASSED=$((PASSED + 1))
else
    error "Le conteneur '$CONTAINER_NAME' n'existe pas"
    echo ""
    show_hint 1 "Avez-vous bien exécuté './commandes.sh' ?"
    show_hint 2 "Vérifiez que vous avez utilisé --name mon-nginx"
fi
echo ""

# ============================================================
# Test 2 : Le conteneur est en cours d'exécution
# ============================================================
info "Test 2/4 : Vérification de l'état du conteneur..."
if check_container_running "$CONTAINER_NAME"; then
    success "Le conteneur '$CONTAINER_NAME' est en cours d'exécution"
    PASSED=$((PASSED + 1))
else
    error "Le conteneur '$CONTAINER_NAME' n'est pas en cours d'exécution"
    echo ""
    show_hint 1 "Le conteneur existe mais ne tourne pas"
    show_hint 2 "Avez-vous utilisé l'option -d (mode détaché) ?"
    show_hint 3 "Vérifiez avec : podman ps -a | grep mon-nginx"
fi
echo ""

# ============================================================
# Test 3 : Le port est correctement mappé
# ============================================================
info "Test 3/4 : Vérification du mappage de port..."
if check_port_mapping "$CONTAINER_NAME" "$EXPECTED_PORT"; then
    success "Le port $EXPECTED_PORT est correctement mappé"
    PASSED=$((PASSED + 1))
else
    error "Le port $EXPECTED_PORT n'est pas correctement mappé"
    echo ""
    show_hint 1 "Le mappage de port utilise l'option -p"
    show_hint 2 "Format : -p PORT_HOTE:PORT_CONTENEUR"
    show_hint 3 "Vous devez mapper 8080:80"
fi
echo ""

# ============================================================
# Test 4 : Le service HTTP répond
# ============================================================
info "Test 4/4 : Vérification de la réponse HTTP..."

# Attendre un peu que le service démarre
if ! check_container_running "$CONTAINER_NAME"; then
    error "Impossible de tester : le conteneur n'est pas en cours d'exécution"
else
    # Attendre que le service soit prêt (max 10 secondes)
    if wait_for_http "$EXPECTED_URL" 10; then
        if check_http_response "$EXPECTED_URL" 200; then
            success "Le service HTTP répond sur $EXPECTED_URL"
            PASSED=$((PASSED + 1))
        else
            error "Le service ne répond pas avec le code HTTP 200"
            show_hint 1 "Le conteneur tourne mais le service ne répond pas"
            show_hint 2 "Vérifiez les logs : podman logs mon-nginx"
        fi
    else
        error "Le service HTTP ne répond pas après 10 secondes"
        echo ""
        show_hint 1 "Le conteneur met peut-être plus de temps à démarrer"
        show_hint 2 "Vérifiez les logs : podman logs mon-nginx"
        show_hint 3 "Testez manuellement : curl http://localhost:8080"
    fi
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
validate_exercise "Exercice 1" $PASSED $TOTAL

# Code de sortie
if [ $PASSED -eq $TOTAL ]; then
    echo ""
    info "💡 Conseil : Explorez votre conteneur avec ces commandes :"
    echo "   podman logs mon-nginx        # Voir les logs"
    echo "   podman inspect mon-nginx     # Voir la configuration détaillée"
    echo "   podman stats mon-nginx       # Voir l'utilisation des ressources"
    echo ""
    info "🧹 Pour nettoyer : ./validation.sh --cleanup"
    echo ""
    exit 0
else
    echo ""
    warning "Consultez le fichier indices.md si vous êtes bloqué"
    echo ""
    exit 1
fi
