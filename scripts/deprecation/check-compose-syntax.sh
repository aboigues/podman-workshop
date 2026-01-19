#!/bin/bash

# Script de verification de la syntaxe Compose depreciee
# Utilise par le workflow GitHub Actions deprecation-check.yml

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Repertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
IGNORE_FILE="${PROJECT_ROOT}/.deprecationignore"

# Compteurs
WARNINGS=0
ERRORS=0
IGNORED=0

# Syntaxes Compose depreciees avec leurs remplacements
declare -A DEPRECATED_SYNTAX=(
    ["^version:"]="Supprimer (obsolete depuis Compose v2) - la version est ignoree"
    ["^[[:space:]]+links:"]="Utiliser les reseaux Docker/Podman - links est deprecie"
    ["^[[:space:]]+scale:"]="Utiliser 'deploy.replicas' ou 'podman-compose up --scale'"
    ["^[[:space:]]+container_name:[[:space:]]+\\\$"]="Eviter les variables dans container_name - peut causer des conflits"
    ["^[[:space:]]+net:"]="Remplacer par 'network_mode' ou 'networks'"
    ["^[[:space:]]+expose:"]="'expose' est souvent inutile - les ports sont exposes au reseau par defaut"
)

# Descriptions des problemes
declare -A SYNTAX_DESCRIPTIONS=(
    ["^version:"]="Directive 'version' obsolete"
    ["^[[:space:]]+links:"]="Directive 'links' depreciee"
    ["^[[:space:]]+scale:"]="Directive 'scale' depreciee"
    ["^[[:space:]]+container_name:[[:space:]]+\\\$"]="Variable dans 'container_name'"
    ["^[[:space:]]+net:"]="Directive 'net' depreciee"
    ["^[[:space:]]+expose:"]="Directive 'expose' potentiellement inutile"
)

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Verifie la syntaxe depreciee dans les fichiers Compose."
    echo ""
    echo "Options:"
    echo "  -h, --help      Afficher cette aide"
    echo "  -v, --verbose   Mode verbeux"
    echo "  -q, --quiet     Mode silencieux (uniquement les erreurs)"
    echo "  --github        Format de sortie pour GitHub Actions"
    echo ""
}

# Fonction pour verifier si un pattern est ignore
is_ignored() {
    local syntax="$1"
    local file="$2"

    if [[ ! -f "$IGNORE_FILE" ]]; then
        return 1
    fi

    local rel_file="${file#$PROJECT_ROOT/}"

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Format: IGNORE_COMPOSE:syntax_key:glob
        if [[ "$line" =~ ^IGNORE_COMPOSE:([^:]+):(.+)$ ]]; then
            local ignore_syntax="${BASH_REMATCH[1]}"
            local ignore_glob="${BASH_REMATCH[2]}"

            if [[ "$syntax" == *"$ignore_syntax"* ]]; then
                # shellcheck disable=SC2053
                if [[ "$rel_file" == $ignore_glob ]]; then
                    return 0
                fi
            fi
        fi
    done < "$IGNORE_FILE"

    return 1
}

# Fonction pour verifier un fichier compose
check_compose_file() {
    local file="$1"
    local verbose="$2"
    local github="$3"

    local rel_file="${file#$PROJECT_ROOT/}"

    [[ "$verbose" == "true" ]] && echo -e "${BLUE}Analyse:${NC} $rel_file"

    for pattern in "${!DEPRECATED_SYNTAX[@]}"; do
        local replacement="${DEPRECATED_SYNTAX[$pattern]}"
        local description="${SYNTAX_DESCRIPTIONS[$pattern]}"

        # Rechercher le pattern dans le fichier
        while IFS=: read -r line_num content; do
            [[ -z "$line_num" ]] && continue

            # Verifier si c'est ignore
            if is_ignored "$pattern" "$file"; then
                IGNORED=$((IGNORED + 1))
                [[ "$verbose" == "true" ]] && echo -e "${YELLOW}[IGNORE]${NC} $rel_file:$line_num - $description"
                continue
            fi

            WARNINGS=$((WARNINGS + 1))

            if [[ "$github" == "true" ]]; then
                echo "::warning file=${rel_file},line=${line_num}::$description - $replacement"
            else
                echo -e "${YELLOW}[DEPRECIE]${NC} ${rel_file}:${line_num}"
                echo -e "  Probleme: ${RED}$description${NC}"
                echo -e "  Contenu: $(echo "$content" | sed 's/^[[:space:]]*//')"
                echo -e "  Recommandation: ${GREEN}$replacement${NC}"
                echo ""
            fi
        done < <(grep -n -E "$pattern" "$file" 2>/dev/null || true)
    done

    return 0
}

# Fonction pour analyser les fichiers Compose
check_compose_files() {
    local verbose=${1:-false}
    local github=${2:-false}
    local quiet=${3:-false}

    [[ "$quiet" != "true" ]] && echo -e "${BLUE}=== Verification de la syntaxe Compose depreciee ===${NC}"
    [[ "$quiet" != "true" ]] && echo ""

    # Trouver tous les fichiers compose
    while IFS= read -r compose_file; do
        [[ -z "$compose_file" ]] && continue
        check_compose_file "$compose_file" "$verbose" "$github"
    done < <(find "$PROJECT_ROOT" -type f \( \
        -name "docker-compose.yml" -o \
        -name "docker-compose.yaml" -o \
        -name "compose.yml" -o \
        -name "compose.yaml" -o \
        -name "*compose*.yml" -o \
        -name "*compose*.yaml" \
    \) 2>/dev/null || true)

    return 0
}

# Fonction pour generer le resume
generate_summary() {
    local github=${1:-false}

    echo ""
    echo -e "${BLUE}=== Resume ===${NC}"
    echo -e "Avertissements: ${YELLOW}$WARNINGS${NC}"
    echo -e "Ignores: ${BLUE}$IGNORED${NC}"

    if [[ "$github" == "true" ]]; then
        {
            echo "## Syntaxe Compose"
            echo ""
            echo "| Metrique | Valeur |"
            echo "|----------|--------|"
            echo "| Avertissements | $WARNINGS |"
            echo "| Ignores | $IGNORED |"
            echo ""
            if [[ $WARNINGS -gt 0 ]]; then
                echo "> **Note:** De la syntaxe Compose depreciee a ete detectee."
            else
                echo "> Tous les fichiers Compose utilisent une syntaxe moderne."
            fi
        } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    fi

    return 0
}

# Parse arguments
VERBOSE=false
GITHUB=false
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --github)
            GITHUB=true
            shift
            ;;
        *)
            echo "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Execution principale
check_compose_files "$VERBOSE" "$GITHUB" "$QUIET"
generate_summary "$GITHUB"

exit 0
