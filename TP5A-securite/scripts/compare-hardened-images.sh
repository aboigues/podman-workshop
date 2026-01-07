#!/bin/bash
# compare-hardened-images.sh
# Compare les vulnérabilités et caractéristiques de différentes images durcies

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Comparaison d'images durcies (Python)"
echo "=========================================="
echo ""

# Liste des images à comparer
IMAGES=(
  "python:3.13"
  "python:3.13-slim"
  "python:3.13-alpine"
  "cgr.dev/chainguard/python:latest"
  "gcr.io/distroless/python3-debian12"
  "registry.access.redhat.com/ubi9/python-311"
)

# Tableau pour stocker les résultats
declare -A RESULTS_CRITICAL
declare -A RESULTS_HIGH
declare -A RESULTS_SIZE

echo "📥 Téléchargement des images..."
echo ""

for image in "${IMAGES[@]}"; do
  echo "  - Pulling $image..."
  podman pull "$image" > /dev/null 2>&1 || {
    echo -e "    ${RED}✗ Échec du téléchargement${NC}"
    continue
  }
done

echo ""
echo "🔍 Analyse des vulnérabilités avec Trivy..."
echo ""

# Vérifier si Trivy est installé
if ! command -v trivy &> /dev/null; then
    echo -e "${YELLOW}⚠️  Trivy n'est pas installé${NC}"
    echo ""
    echo "Pour installer Trivy :"
    echo "  # Fedora/RHEL"
    echo "  sudo dnf install trivy"
    echo ""
    echo "  # Debian/Ubuntu"
    echo "  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -"
    echo "  echo 'deb https://aquasecurity.github.io/trivy-repo/deb \$(lsb_release -sc) main' | sudo tee /etc/apt/sources.list.d/trivy.list"
    echo "  sudo apt update && sudo apt install trivy"
    echo ""
    echo "  # Via conteneur (sans installation)"
    echo "  alias trivy='podman run --rm -v /var/run/containers/podman.sock:/var/run/podman/podman.sock aquasec/trivy'"
    echo ""
    exit 1
fi

# Scanner chaque image
for image in "${IMAGES[@]}"; do
  echo -ne "  📦 ${BLUE}$image${NC}"

  # Scanner avec Trivy (ignorer les erreurs si l'image n'est pas disponible)
  if podman image exists "$image" 2>/dev/null; then
    # Compter les vulnérabilités CRITICAL
    critical=$(trivy image --severity CRITICAL --quiet "$image" 2>/dev/null | grep -c "CRITICAL" || echo "0")

    # Compter les vulnérabilités HIGH
    high=$(trivy image --severity HIGH --quiet "$image" 2>/dev/null | grep -c "HIGH" || echo "0")

    # Obtenir la taille de l'image
    size=$(podman images "$image" --format "{{.Size}}" 2>/dev/null | head -1)

    # Stocker les résultats
    RESULTS_CRITICAL["$image"]=$critical
    RESULTS_HIGH["$image"]=$high
    RESULTS_SIZE["$image"]=$size

    echo " ✓"
  else
    echo -e " ${RED}✗ Non disponible${NC}"
  fi
done

echo ""
echo "=========================================="
echo "           RÉSULTATS"
echo "=========================================="
echo ""

# Afficher le tableau des résultats
printf "%-50s | %10s | %10s | %10s\n" "Image" "CRITICAL" "HIGH" "Taille"
printf "%-50s-+-%10s-+-%10s-+-%10s\n" "$(printf '%.0s-' {1..50})" "----------" "----------" "----------"

for image in "${IMAGES[@]}"; do
  if [[ -n "${RESULTS_CRITICAL[$image]}" ]]; then
    critical=${RESULTS_CRITICAL[$image]}
    high=${RESULTS_HIGH[$image]}
    size=${RESULTS_SIZE[$image]}

    # Couleurs selon le nombre de vulnérabilités
    if [[ $critical -eq 0 ]]; then
      critical_color="${GREEN}"
    else
      critical_color="${RED}"
    fi

    if [[ $high -eq 0 ]]; then
      high_color="${GREEN}"
    elif [[ $high -lt 5 ]]; then
      high_color="${YELLOW}"
    else
      high_color="${RED}"
    fi

    printf "%-50s | ${critical_color}%10s${NC} | ${high_color}%10s${NC} | %10s\n" \
      "$image" "$critical" "$high" "$size"
  fi
done

echo ""
echo "=========================================="
echo "         RECOMMANDATIONS"
echo "=========================================="
echo ""

# Trouver l'image avec le moins de vulnérabilités CRITICAL
best_image=""
min_critical=999999

for image in "${IMAGES[@]}"; do
  if [[ -n "${RESULTS_CRITICAL[$image]}" ]]; then
    critical=${RESULTS_CRITICAL[$image]}
    if [[ $critical -lt $min_critical ]]; then
      min_critical=$critical
      best_image=$image
    fi
  fi
done

if [[ -n "$best_image" ]]; then
  echo -e "🥇 ${GREEN}Meilleure option (sécurité) : $best_image${NC}"
  echo "   └─ Vulnérabilités CRITICAL : ${RESULTS_CRITICAL[$best_image]}"
  echo "   └─ Vulnérabilités HIGH : ${RESULTS_HIGH[$best_image]}"
  echo "   └─ Taille : ${RESULTS_SIZE[$best_image]}"
fi

echo ""
echo -e "${BLUE}💡 Recommandations par contexte :${NC}"
echo ""
echo "  🏠 Développement / Projets personnels :"
echo "     → cgr.dev/chainguard/python:latest (gratuit, zéro CVE)"
echo "     → gcr.io/distroless/python3-debian12 (minimaliste)"
echo ""
echo "  🏢 Startup / PME :"
echo "     → cgr.dev/chainguard/python:latest (excellent rapport sécurité/coût)"
echo "     → registry.access.redhat.com/ubi9/python-311 (gratuit, stable)"
echo ""
echo "  🏦 Entreprise réglementée (finance, santé) :"
echo "     → Chainguard Enterprise (payant, FIPS, SLA)"
echo "     → Red Hat UBI + RHEL (payant, support 24/7)"
echo ""
echo "  🎖️  Gouvernement / Défense :"
echo "     → Iron Bank (DISA STIG, FedRAMP)"
echo ""

echo "=========================================="
echo ""
echo "Pour construire une image durcie avec l'un de ces exemples :"
echo "  cd ../exemples"
echo "  podman build -t myapp:distroless -f Dockerfile-distroless ."
echo "  podman build -t myapp:chainguard -f Dockerfile-chainguard ."
echo "  podman build -t myapp:ubi -f Dockerfile-ubi-micro ."
echo ""
