#!/bin/bash

# Utilitaires de validation pour les exercices du workshop Podman
# Ce fichier contient des fonctions pour valider les commandes des apprenants

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher un message de succès
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Fonction pour afficher un message d'erreur
error() {
    echo -e "${RED}✗${NC} $1"
}

# Fonction pour afficher un message d'information
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Fonction pour afficher un avertissement
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Fonction pour afficher un en-tête d'exercice
exercice_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# Vérifier si un conteneur existe
check_container_exists() {
    local container_name=$1
    if podman ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Vérifier si un conteneur est en cours d'exécution
check_container_running() {
    local container_name=$1
    if podman ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Vérifier si un port est mappé correctement
check_port_mapping() {
    local container_name=$1
    local expected_port=$2
    local actual_port=$(podman port "$container_name" 2>/dev/null | grep -oP "0.0.0.0:\K$expected_port" || echo "")

    if [ "$actual_port" == "$expected_port" ]; then
        return 0
    else
        return 1
    fi
}

# Vérifier si un service HTTP répond
check_http_response() {
    local url=$1
    local expected_code=${2:-200}
    local timeout=${3:-5}

    local http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")

    if [ "$http_code" == "$expected_code" ]; then
        return 0
    else
        return 1
    fi
}

# Vérifier si une image existe localement
check_image_exists() {
    local image_name=$1
    if podman images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${image_name}$"; then
        return 0
    else
        return 1
    fi
}

# Vérifier les logs d'un conteneur pour un pattern
check_logs_contain() {
    local container_name=$1
    local pattern=$2
    if podman logs "$container_name" 2>&1 | grep -q "$pattern"; then
        return 0
    else
        return 1
    fi
}

# Attendre qu'un conteneur soit prêt
wait_for_container() {
    local container_name=$1
    local timeout=${2:-30}
    local counter=0

    while [ $counter -lt $timeout ]; do
        if check_container_running "$container_name"; then
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
    done
    return 1
}

# Attendre qu'un service HTTP soit prêt
wait_for_http() {
    local url=$1
    local timeout=${2:-30}
    local counter=0

    while [ $counter -lt $timeout ]; do
        if check_http_response "$url" 200 2; then
            return 0
        fi
        sleep 1
        counter=$((counter + 1))
    done
    return 1
}

# Afficher un indice
show_hint() {
    local level=$1
    shift
    echo ""
    echo -e "${YELLOW}💡 Indice niveau $level:${NC}"
    echo -e "   $*"
    echo ""
}

# Afficher la progression
show_progress() {
    local current=$1
    local total=$2
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 5))
    local empty=$((20 - filled))

    echo -n "Progression: ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    echo -e "] ${percentage}% (${current}/${total})"
}

# Valider un exercice complet
validate_exercise() {
    local exercise_name=$1
    local passed=$2
    local total=$3

    exercice_header "Résultat: $exercise_name"

    if [ "$passed" -eq "$total" ]; then
        success "Exercice réussi ! Tous les tests sont passés ($passed/$total)"
        echo ""
        info "Vous pouvez passer à l'exercice suivant !"
        return 0
    else
        error "Exercice incomplet. Tests réussis: $passed/$total"
        echo ""
        warning "Revoyez les étapes qui ont échoué et réessayez."
        return 1
    fi
}

# Nettoyer les ressources d'un exercice
cleanup_exercise() {
    local prefix=$1
    info "Nettoyage des ressources de l'exercice..."

    # Arrêter et supprimer les conteneurs
    podman ps -a --format '{{.Names}}' | grep "^${prefix}" | while read -r container; do
        podman rm -f "$container" >/dev/null 2>&1 || true
    done

    success "Nettoyage terminé"
}

# Exporter les fonctions
export -f success error info warning exercice_header
export -f check_container_exists check_container_running check_port_mapping
export -f check_http_response check_image_exists check_logs_contain
export -f wait_for_container wait_for_http
export -f show_hint show_progress validate_exercise cleanup_exercise
