#!/bin/bash

# Validation exercice 3

source ../../../lib/validation-utils.sh

CONTAINER_NAME="lifecycle-test"

if [ "$1" == "--cleanup" ]; then
    cleanup_exercise "$CONTAINER_NAME"
    exit 0
fi

exercice_header "Validation Exercice 3: Cycle de vie"

PASSED=0
TOTAL=1

# Test : Le conteneur n'existe plus (a été supprimé)
info "Test 1/1 : Vérification que le conteneur a été supprimé..."
if ! check_container_exists "$CONTAINER_NAME"; then
    success "Le conteneur '$CONTAINER_NAME' a bien été supprimé"
    PASSED=$((PASSED + 1))
else
    error "Le conteneur '$CONTAINER_NAME' existe encore"
    show_hint 1 "Vous devez supprimer le conteneur avec 'podman rm -f'"
fi
echo ""

show_progress $PASSED $TOTAL
echo ""

validate_exercise "Exercice 3" $PASSED $TOTAL

if [ $PASSED -eq $TOTAL ]; then
    echo ""
    info "💡 Cycle de vie des conteneurs :"
    echo "   podman stop    # Arrête (graceful)"
    echo "   podman start   # Redémarre un conteneur arrêté"
    echo "   podman restart # Redémarre un conteneur en cours"
    echo "   podman rm      # Supprime (conteneur doit être arrêté)"
    echo "   podman rm -f   # Force la suppression (stop + rm)"
    echo ""
    exit 0
else
    exit 1
fi
