#!/bin/bash

set -e
source ../../../lib/validation-utils.sh

IMAGE_NAME="mon-app-python:v1"
CONTAINER_NAME="test-python-validation"

if [ "$1" == "--cleanup" ]; then
    podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    exit 0
fi

exercice_header "Validation Exercice 1: Dockerfile Python Flask"

PASSED=0
TOTAL=4

# Test 1 : L'image existe
info "Test 1/4 : Vérification de l'image..."
if check_image_exists "$IMAGE_NAME"; then
    success "L'image $IMAGE_NAME existe"
    PASSED=$((PASSED + 1))
else
    error "L'image $IMAGE_NAME n'existe pas"
    show_hint 1 "Construisez l'image avec ./build.sh"
fi
echo ""

# Test 2 : Le conteneur démarre
info "Test 2/4 : Test de démarrage du conteneur..."
podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
if podman run -d --name "$CONTAINER_NAME" -p 5001:5000 "$IMAGE_NAME" >/dev/null 2>&1; then
    success "Le conteneur démarre correctement"
    PASSED=$((PASSED + 1))
else
    error "Erreur au démarrage du conteneur"
fi
echo ""

# Test 3 : Le service répond
info "Test 3/4 : Test de la réponse HTTP..."
if wait_for_http "http://localhost:5001" 15; then
    success "Le service répond sur le port 5000"
    PASSED=$((PASSED + 1))
else
    error "Le service ne répond pas"
fi
echo ""

# Test 4 : Contenu de la réponse
info "Test 4/4 : Vérification du contenu..."
if curl -s http://localhost:5001 | grep -q "Hello from Flask"; then
    success "L'application retourne le bon message"
    PASSED=$((PASSED + 1))
else
    error "Le message n'est pas celui attendu"
fi
echo ""

# Nettoyage
podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

show_progress $PASSED $TOTAL
echo ""

validate_exercise "Exercice 1 - TP2" $PASSED $TOTAL

if [ $PASSED -eq $TOTAL ]; then
    echo ""
    info "🎉 Bravo ! Vous avez créé votre premier Dockerfile !"
    echo ""
    exit 0
else
    exit 1
fi
