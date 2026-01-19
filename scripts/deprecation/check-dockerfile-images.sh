#!/bin/bash

# Script de verification des versions d'images de base dans les Dockerfiles
# Utilise l'API endoflife.date pour verifier les versions en fin de vie
# https://endoflife.date/docs/api

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
CACHE_DIR="${SCRIPT_DIR}/.cache"
CACHE_TTL=3600  # Cache valide pendant 1 heure

# Compteurs
WARNINGS=0
ERRORS=0
IGNORED=0

# Mapping des noms d'images vers les produits endoflife.date
declare -A IMAGE_TO_PRODUCT=(
    ["python"]="python"
    ["node"]="nodejs"
    ["nodejs"]="nodejs"
    ["golang"]="go"
    ["go"]="go"
    ["ruby"]="ruby"
    ["php"]="php"
    ["nginx"]="nginx"
    ["alpine"]="alpine"
    ["ubuntu"]="ubuntu"
    ["debian"]="debian"
    ["postgres"]="postgresql"
    ["postgresql"]="postgresql"
    ["redis"]="redis"
    ["mysql"]="mysql"
    ["mariadb"]="mariadb"
)

# Fonction pour afficher l'aide
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Verifie les versions des images de base dans les Dockerfiles"
    echo "en utilisant l'API endoflife.date comme reference."
    echo ""
    echo "Options:"
    echo "  -h, --help       Afficher cette aide"
    echo "  -v, --verbose    Mode verbeux"
    echo "  -q, --quiet      Mode silencieux (uniquement les erreurs)"
    echo "  --github         Format de sortie pour GitHub Actions"
    echo "  --no-cache       Ignorer le cache et forcer les requetes API"
    echo "  --clear-cache    Vider le cache avant execution"
    echo ""
}

# Fonction pour verifier si un pattern est ignore
is_ignored() {
    local image="$1"
    local version="$2"
    local file="$3"

    if [[ ! -f "$IGNORE_FILE" ]]; then
        return 1
    fi

    local rel_file="${file#$PROJECT_ROOT/}"

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Format: IGNORE_IMAGE:image:version:glob
        if [[ "$line" =~ ^IGNORE_IMAGE:([^:]+):([^:]+):(.+)$ ]]; then
            local ignore_image="${BASH_REMATCH[1]}"
            local ignore_version="${BASH_REMATCH[2]}"
            local ignore_glob="${BASH_REMATCH[3]}"

            if [[ "$image" == "$ignore_image" && "$version" == "$ignore_version" ]]; then
                # shellcheck disable=SC2053
                if [[ "$rel_file" == $ignore_glob ]]; then
                    return 0
                fi
            fi
        fi
    done < "$IGNORE_FILE"

    return 1
}

# Fonction pour obtenir les donnees EOL depuis le cache ou l'API
get_eol_data() {
    local product="$1"
    local use_cache="$2"
    local cache_file="${CACHE_DIR}/${product}.json"

    # Creer le repertoire de cache si necessaire
    mkdir -p "$CACHE_DIR"

    # Verifier le cache
    if [[ "$use_cache" == "true" && -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt $CACHE_TTL ]]; then
            cat "$cache_file"
            return 0
        fi
    fi

    # Requete API
    local api_url="https://endoflife.date/api/${product}.json"
    local response
    response=$(curl -sf --max-time 10 "$api_url" 2>/dev/null) || return 1

    # Sauvegarder dans le cache
    echo "$response" > "$cache_file"
    echo "$response"
}

# Fonction pour extraire le cycle de version (ex: "3.11" de "3.11.5-slim")
extract_version_cycle() {
    local tag="$1"
    local product="$2"

    # Extraire major.minor selon le produit
    case "$product" in
        python|go|ruby|php)
            # Format: X.Y ou X.Y.Z -> X.Y
            echo "$tag" | grep -oE '^[0-9]+\.[0-9]+' | head -1
            ;;
        nodejs)
            # Format: X ou X.Y -> X
            echo "$tag" | grep -oE '^[0-9]+' | head -1
            ;;
        alpine)
            # Format: X.Y -> X.Y
            echo "$tag" | grep -oE '^[0-9]+\.[0-9]+' | head -1
            ;;
        ubuntu)
            # Format: X.Y ou XX.YY -> XX.YY
            echo "$tag" | grep -oE '^[0-9]+\.[0-9]+' | head -1
            ;;
        debian)
            # Format: X ou nom -> X
            echo "$tag" | grep -oE '^[0-9]+' | head -1
            ;;
        postgresql|mysql|mariadb|redis|nginx)
            # Format: X ou X.Y -> X
            echo "$tag" | grep -oE '^[0-9]+' | head -1
            ;;
        *)
            echo "$tag" | grep -oE '^[0-9]+(\.[0-9]+)?' | head -1
            ;;
    esac
}

# Fonction pour verifier si une version est EOL
check_version_eol() {
    local product="$1"
    local cycle="$2"
    local eol_data="$3"

    if [[ -z "$eol_data" || -z "$cycle" ]]; then
        return 2  # Impossible de verifier
    fi

    # Chercher le cycle dans les donnees EOL
    local cycle_data
    cycle_data=$(echo "$eol_data" | jq -r --arg c "$cycle" '.[] | select(.cycle == $c)' 2>/dev/null)

    if [[ -z "$cycle_data" ]]; then
        # Essayer avec juste le numero majeur pour certains produits
        cycle_data=$(echo "$eol_data" | jq -r --arg c "$cycle" '.[] | select(.cycle == ($c | tostring))' 2>/dev/null)
    fi

    if [[ -z "$cycle_data" ]]; then
        return 2  # Version non trouvee dans l'API
    fi

    # Extraire la date EOL
    local eol_date
    eol_date=$(echo "$cycle_data" | jq -r '.eol // empty' 2>/dev/null)

    if [[ -z "$eol_date" || "$eol_date" == "false" ]]; then
        return 1  # Pas de date EOL = toujours supporte
    fi

    # Comparer avec aujourd'hui
    local today
    today=$(date +%Y-%m-%d)

    if [[ "$eol_date" < "$today" ]]; then
        return 0  # EOL atteint
    fi

    # Verifier si EOL dans les 6 prochains mois (warning)
    local six_months_later
    six_months_later=$(date -d "+6 months" +%Y-%m-%d 2>/dev/null || date -v+6m +%Y-%m-%d 2>/dev/null || echo "")

    if [[ -n "$six_months_later" && "$eol_date" < "$six_months_later" ]]; then
        return 3  # EOL proche
    fi

    return 1  # OK
}

# Fonction pour obtenir la date EOL d'une version
get_eol_date() {
    local product="$1"
    local cycle="$2"
    local eol_data="$3"

    local cycle_data
    cycle_data=$(echo "$eol_data" | jq -r --arg c "$cycle" '.[] | select(.cycle == $c)' 2>/dev/null)

    if [[ -z "$cycle_data" ]]; then
        cycle_data=$(echo "$eol_data" | jq -r --arg c "$cycle" '.[] | select(.cycle == ($c | tostring))' 2>/dev/null)
    fi

    echo "$cycle_data" | jq -r '.eol // "N/A"' 2>/dev/null
}

# Fonction pour obtenir la derniere version stable
get_latest_stable() {
    local eol_data="$1"

    # Trouver la premiere version non-EOL (les donnees sont triees par version decroissante)
    local today
    today=$(date +%Y-%m-%d)

    echo "$eol_data" | jq -r --arg today "$today" '
        [.[] | select(.eol == false or .eol > $today)] | first | .cycle // empty
    ' 2>/dev/null
}

# Fonction pour verifier une image
check_image() {
    local file="$1"
    local line_num="$2"
    local from_line="$3"
    local verbose="$4"
    local github="$5"
    local use_cache="$6"

    local rel_file="${file#$PROJECT_ROOT/}"

    # Ignorer les lignes avec des placeholders (templates d'exercices)
    if [[ "$from_line" =~ ___|\$\{|XXXXX|\<.*\> ]]; then
        [[ "$verbose" == "true" ]] && echo -e "${BLUE}[SKIP]${NC} $rel_file:$line_num - Template placeholder detecte"
        return 0
    fi

    # Extraire l'image et le tag de la ligne FROM
    local image_spec
    image_spec=$(echo "$from_line" | sed -E 's/^FROM\s+(--[^\s]+\s+)*//i' | awk '{print $1}')

    # Separer image et tag
    local image tag
    if [[ "$image_spec" == *":"* ]]; then
        image="${image_spec%%:*}"
        tag="${image_spec#*:}"
    else
        image="$image_spec"
        tag="latest"
    fi

    # Extraire le nom de base de l'image (sans registry)
    local base_image="${image##*/}"

    # Verifier :latest
    if [[ "$tag" == "latest" ]]; then
        if ! is_ignored "$base_image" "latest" "$file"; then
            WARNINGS=$((WARNINGS + 1))
            if [[ "$github" == "true" ]]; then
                echo "::warning file=${rel_file},line=${line_num}::Tag ':latest' detecte pour '$image' - Specifiez une version explicite"
            else
                echo -e "${YELLOW}[LATEST]${NC} ${rel_file}:${line_num}"
                echo -e "  Image: ${YELLOW}$image:latest${NC}"
                echo -e "  Recommandation: ${GREEN}Specifier une version explicite${NC}"
                echo ""
            fi
        else
            IGNORED=$((IGNORED + 1))
            [[ "$verbose" == "true" ]] && echo -e "${YELLOW}[IGNORE]${NC} $rel_file:$line_num - $base_image:latest"
        fi
        return 0
    fi

    # Trouver le produit correspondant sur endoflife.date
    local product="${IMAGE_TO_PRODUCT[$base_image]}"

    if [[ -z "$product" ]]; then
        [[ "$verbose" == "true" ]] && echo -e "${BLUE}[SKIP]${NC} $rel_file:$line_num - Produit '$base_image' non supporte par endoflife.date"
        return 0
    fi

    # Extraire le cycle de version
    local cycle
    cycle=$(extract_version_cycle "$tag" "$product")

    if [[ -z "$cycle" ]]; then
        [[ "$verbose" == "true" ]] && echo -e "${BLUE}[SKIP]${NC} $rel_file:$line_num - Impossible d'extraire la version de '$tag'"
        return 0
    fi

    # Obtenir les donnees EOL
    local eol_data
    eol_data=$(get_eol_data "$product" "$use_cache")

    if [[ -z "$eol_data" ]]; then
        [[ "$verbose" == "true" ]] && echo -e "${YELLOW}[WARN]${NC} $rel_file:$line_num - Impossible de recuperer les donnees EOL pour '$product'"
        return 0
    fi

    # Verifier le statut EOL
    local eol_status
    check_version_eol "$product" "$cycle" "$eol_data" && eol_status=$? || eol_status=$?

    case $eol_status in
        0)  # EOL atteint
            if is_ignored "$base_image" "$tag" "$file"; then
                IGNORED=$((IGNORED + 1))
                [[ "$verbose" == "true" ]] && echo -e "${YELLOW}[IGNORE]${NC} $rel_file:$line_num - $base_image:$tag"
            else
                WARNINGS=$((WARNINGS + 1))
                local eol_date
                eol_date=$(get_eol_date "$product" "$cycle" "$eol_data")
                local latest
                latest=$(get_latest_stable "$eol_data")

                if [[ "$github" == "true" ]]; then
                    echo "::warning file=${rel_file},line=${line_num}::Version EOL '$image:$tag' (fin de vie: $eol_date) - Recommande: $base_image:$latest"
                else
                    echo -e "${RED}[EOL]${NC} ${rel_file}:${line_num}"
                    echo -e "  Image: ${RED}$image:$tag${NC}"
                    echo -e "  Fin de vie: ${RED}$eol_date${NC}"
                    echo -e "  Source: ${BLUE}https://endoflife.date/$product${NC}"
                    [[ -n "$latest" ]] && echo -e "  Recommandation: ${GREEN}$base_image:$latest${NC}"
                    echo ""
                fi
            fi
            ;;
        3)  # EOL proche (< 6 mois)
            if is_ignored "$base_image" "$tag" "$file"; then
                IGNORED=$((IGNORED + 1))
                [[ "$verbose" == "true" ]] && echo -e "${YELLOW}[IGNORE]${NC} $rel_file:$line_num - $base_image:$tag"
            else
                WARNINGS=$((WARNINGS + 1))
                local eol_date
                eol_date=$(get_eol_date "$product" "$cycle" "$eol_data")
                local latest
                latest=$(get_latest_stable "$eol_data")

                if [[ "$github" == "true" ]]; then
                    echo "::warning file=${rel_file},line=${line_num}::Version '$image:$tag' en fin de vie prochaine ($eol_date) - Planifier migration vers $base_image:$latest"
                else
                    echo -e "${YELLOW}[EOL PROCHE]${NC} ${rel_file}:${line_num}"
                    echo -e "  Image: ${YELLOW}$image:$tag${NC}"
                    echo -e "  Fin de vie: ${YELLOW}$eol_date${NC}"
                    echo -e "  Source: ${BLUE}https://endoflife.date/$product${NC}"
                    [[ -n "$latest" ]] && echo -e "  Recommandation: ${GREEN}Planifier migration vers $base_image:$latest${NC}"
                    echo ""
                fi
            fi
            ;;
        1)  # OK
            [[ "$verbose" == "true" ]] && echo -e "${GREEN}[OK]${NC} $rel_file:$line_num - $base_image:$tag"
            ;;
        2)  # Impossible de verifier
            [[ "$verbose" == "true" ]] && echo -e "${BLUE}[SKIP]${NC} $rel_file:$line_num - Version '$cycle' non trouvee dans endoflife.date"
            ;;
    esac

    return 0
}

# Fonction pour analyser les Dockerfiles
check_dockerfiles() {
    local verbose=${1:-false}
    local github=${2:-false}
    local quiet=${3:-false}
    local use_cache=${4:-true}

    [[ "$quiet" != "true" ]] && echo -e "${BLUE}=== Verification des images de base (via endoflife.date) ===${NC}"
    [[ "$quiet" != "true" ]] && echo ""

    # Verifier la disponibilite de curl et jq
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Erreur: curl est requis${NC}"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Erreur: jq est requis${NC}"
        exit 1
    fi

    # Trouver tous les Dockerfiles
    while IFS= read -r dockerfile; do
        [[ -z "$dockerfile" ]] && continue

        [[ "$verbose" == "true" ]] && echo -e "${BLUE}Analyse:${NC} ${dockerfile#$PROJECT_ROOT/}"

        # Lire chaque ligne FROM
        local line_num=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            line_num=$((line_num + 1))
            # Detecter les lignes FROM (insensible a la casse)
            if [[ "$line" =~ ^[[:space:]]*[Ff][Rr][Oo][Mm][[:space:]] ]]; then
                check_image "$dockerfile" "$line_num" "$line" "$verbose" "$github" "$use_cache"
            fi
        done < "$dockerfile"
    done < <(find "$PROJECT_ROOT" -type f \( -name "Dockerfile" -o -name "Dockerfile.*" -o -name "*.dockerfile" \) 2>/dev/null || true)

    return 0
}

# Fonction pour generer le resume
generate_summary() {
    local github=${1:-false}

    echo ""
    echo -e "${BLUE}=== Resume ===${NC}"
    echo -e "Avertissements: ${YELLOW}$WARNINGS${NC}"
    echo -e "Ignores: ${BLUE}$IGNORED${NC}"
    echo -e "Source: ${BLUE}https://endoflife.date${NC}"

    if [[ "$github" == "true" ]]; then
        {
            echo "## Images de Base Dockerfile"
            echo ""
            echo "| Metrique | Valeur |"
            echo "|----------|--------|"
            echo "| Avertissements | $WARNINGS |"
            echo "| Ignores | $IGNORED |"
            echo ""
            echo "Source: [endoflife.date](https://endoflife.date)"
            echo ""
            if [[ $WARNINGS -gt 0 ]]; then
                echo "> **Note:** Des versions d'images en fin de vie ont ete detectees."
            else
                echo "> Toutes les images utilisent des versions supportees."
            fi
        } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
    fi

    return 0
}

# Parse arguments
VERBOSE=false
GITHUB=false
QUIET=false
USE_CACHE=true

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
        --no-cache)
            USE_CACHE=false
            shift
            ;;
        --clear-cache)
            rm -rf "$CACHE_DIR"
            echo "Cache vide"
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
check_dockerfiles "$VERBOSE" "$GITHUB" "$QUIET" "$USE_CACHE"
generate_summary "$GITHUB"

exit 0
