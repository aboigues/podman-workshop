#!/bin/bash

# Script de detection des commandes Podman depreciees
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
IGNORED=0

# Liste des commandes Podman depreciees avec leurs remplacements
declare -A DEPRECATED_COMMANDS=(
    ["podman generate systemd"]="Quadlet (Podman 4.4+) - voir https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html"
    ["podman varlink"]="API REST Podman (supprime dans Podman 4.0)"
    ["podman container runlabel"]="Supprime - utiliser des scripts ou podman run directement"
    ["podman image sign"]="podman image sign --sign-by (nouveau format)"
)

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Detecte les commandes Podman depreciees dans les fichiers du projet."
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
    local pattern="$1"
    local file="$2"

    if [[ ! -f "$IGNORE_FILE" ]]; then
        return 1
    fi

    # Normaliser le chemin du fichier (relatif au projet)
    local rel_file="${file#$PROJECT_ROOT/}"

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Ignorer les commentaires et lignes vides
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Format: IGNORE:pattern:glob
        if [[ "$line" =~ ^IGNORE:(.+):(.+)$ ]]; then
            local ignore_pattern="${BASH_REMATCH[1]}"
            local ignore_glob="${BASH_REMATCH[2]}"

            # Verifier si le pattern correspond
            if [[ "$pattern" == *"$ignore_pattern"* ]]; then
                # Verifier si le fichier correspond au glob
                # shellcheck disable=SC2053
                if [[ "$rel_file" == $ignore_glob ]]; then
                    return 0
                fi
            fi
        fi
    done < "$IGNORE_FILE"

    return 1
}

# Fonction pour rechercher les commandes depreciees
check_deprecated() {
    local verbose=${1:-false}
    local github=${2:-false}
    local quiet=${3:-false}

    [[ "$quiet" != "true" ]] && echo -e "${BLUE}=== Verification des commandes Podman depreciees ===${NC}"
    [[ "$quiet" != "true" ]] && echo ""

    for cmd in "${!DEPRECATED_COMMANDS[@]}"; do
        local replacement="${DEPRECATED_COMMANDS[$cmd]}"
        local pattern
        # Echapper les espaces pour grep
        pattern=$(echo "$cmd" | sed 's/ /\\s\\+/g')

        # Rechercher dans les fichiers .sh et .md
        while IFS=: read -r file line_num content; do
            [[ -z "$file" ]] && continue

            # Verifier si c'est ignore
            if is_ignored "$cmd" "$file"; then
                IGNORED=$((IGNORED + 1))
                [[ "$verbose" == "true" ]] && echo -e "${YELLOW}[IGNORE]${NC} $file:$line_num - $cmd"
                continue
            fi

            WARNINGS=$((WARNINGS + 1))

            if [[ "$github" == "true" ]]; then
                # Format GitHub Actions
                echo "::warning file=${file#$PROJECT_ROOT/},line=${line_num}::Commande depreciee: '$cmd' - Remplacement: $replacement"
            else
                echo -e "${YELLOW}[DEPRECIE]${NC} ${file#$PROJECT_ROOT/}:${line_num}"
                echo -e "  Commande: ${RED}$cmd${NC}"
                echo -e "  Remplacement: ${GREEN}$replacement${NC}"
                [[ "$verbose" == "true" ]] && echo -e "  Contexte: $content"
                echo ""
            fi
        done < <(grep -rn --include="*.sh" --include="*.md" -E "$pattern" "$PROJECT_ROOT" 2>/dev/null || true)
    done

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
        # Generer le summary GitHub
        {
            echo "## Commandes Podman Depreciees"
            echo ""
            echo "| Metrique | Valeur |"
            echo "|----------|--------|"
            echo "| Avertissements | $WARNINGS |"
            echo "| Ignores | $IGNORED |"
            echo ""
            if [[ $WARNINGS -gt 0 ]]; then
                echo "> **Note:** Des commandes depreciees ont ete detectees. Consultez les logs pour plus de details."
            else
                echo "> Aucune commande depreciee detectee."
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
check_deprecated "$VERBOSE" "$GITHUB" "$QUIET"
generate_summary "$GITHUB"

# Code de sortie (0 meme avec des warnings pour ne pas bloquer le CI)
exit 0
