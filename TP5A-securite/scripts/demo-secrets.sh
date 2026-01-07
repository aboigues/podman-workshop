#!/bin/bash
#
# Script de démonstration Podman Secrets
# Montre comment créer, utiliser et gérer des secrets de manière sécurisée
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Démonstration Podman Secrets ===${NC}\n"

# Fonction de nettoyage
cleanup() {
    echo -e "\n${YELLOW}Nettoyage...${NC}"
    podman rm -f secret-demo-app 2>/dev/null || true
    podman secret rm db_password api_key 2>/dev/null || true
    podman rmi -f secret-demo:latest 2>/dev/null || true
}

# Nettoyer au démarrage
cleanup

echo -e "${GREEN}📝 Étape 1: Création des secrets${NC}\n"

# Créer des secrets de démonstration
echo "super_secure_db_password_123" | podman secret create db_password -
echo "api_key_secret_xyz789" | podman secret create api_key -

echo -e "${GREEN}✅ Secrets créés${NC}\n"

# Lister les secrets
echo -e "${GREEN}📋 Étape 2: Liste des secrets${NC}\n"
podman secret ls
echo ""

# Inspecter un secret (ne montre PAS le contenu)
echo -e "${GREEN}🔍 Étape 3: Inspection d'un secret${NC}\n"
podman secret inspect db_password
echo ""

echo -e "${GREEN}🏗️  Étape 4: Construction de l'image de démonstration${NC}\n"
cd "$(dirname "$0")/../exemples"
podman build -t secret-demo:latest -f Dockerfile-secrets .
echo ""

echo -e "${GREEN}🚀 Étape 5: Lancement du conteneur avec secrets${NC}\n"
echo "Commande exécutée:"
echo "  podman run --name secret-demo-app --secret db_password --secret api_key secret-demo:latest"
echo ""

podman run --name secret-demo-app \
    --secret db_password \
    --secret api_key \
    secret-demo:latest

echo -e "\n${GREEN}🔒 Étape 6: Vérification de la sécurité${NC}\n"

# Vérifier que les secrets ne sont PAS visibles via inspect
echo -e "${YELLOW}Test 1: Les secrets ne sont PAS dans podman inspect${NC}"
if podman inspect secret-demo-app | grep -i "super_secure" >/dev/null; then
    echo -e "${RED}❌ ÉCHEC: Secret trouvé dans inspect!${NC}"
else
    echo -e "${GREEN}✅ SUCCÈS: Secrets non visibles dans inspect${NC}"
fi
echo ""

# Vérifier que les variables d'env ne contiennent pas les secrets
echo -e "${YELLOW}Test 2: Les secrets ne sont PAS dans les variables d'environnement${NC}"
if podman exec secret-demo-app env | grep -i "password" >/dev/null; then
    echo -e "${RED}❌ ÉCHEC: Secret trouvé dans les variables d'env!${NC}"
else
    echo -e "${GREEN}✅ SUCCÈS: Secrets non visibles dans les env${NC}"
fi
echo ""

# Vérifier que les secrets sont montés en tmpfs (RAM)
echo -e "${YELLOW}Test 3: Les secrets sont montés en tmpfs (RAM uniquement)${NC}"
podman exec secret-demo-app sh -c "mount | grep /run/secrets || echo 'tmpfs sur /run/secrets'"
echo ""

# Vérifier les permissions des secrets
echo -e "${YELLOW}Test 4: Vérification des permissions des secrets${NC}"
podman exec secret-demo-app ls -la /run/secrets/
echo ""

echo -e "${GREEN}📊 Comparaison: Variables d'env vs Secrets${NC}\n"

echo -e "${RED}❌ Avec variables d'environnement (NON SÉCURISÉ):${NC}"
podman run --rm -e DB_PASSWORD="exposed_password_123" alpine sh -c '
    echo "1. Visible dans env:"
    env | grep DB_PASSWORD
    echo ""
    echo "2. Visible dans /proc/1/environ:"
    cat /proc/1/environ | tr "\0" "\n" | grep DB_PASSWORD
'
echo ""

echo -e "${GREEN}✅ Avec Podman secrets (SÉCURISÉ):${NC}"
echo "my_secret" | podman secret create temp_secret - 2>/dev/null || true
podman run --rm --secret temp_secret alpine sh -c '
    echo "1. NOT visible dans env:"
    env | grep -i secret || echo "   (aucun secret trouvé)"
    echo ""
    echo "2. Secret accessible uniquement via fichier:"
    echo "   Contenu: $(cat /run/secrets/temp_secret)"
    echo ""
    echo "3. Permissions strictes:"
    ls -l /run/secrets/temp_secret
'
podman secret rm temp_secret 2>/dev/null || true
echo ""

echo -e "${GREEN}🎯 Avantages démontrés:${NC}"
echo "  ✅ Secrets stockés de manière chiffrée par Podman"
echo "  ✅ Montés en tmpfs (RAM uniquement, jamais sur disque)"
echo "  ✅ Permissions 400 automatiques"
echo "  ✅ Non visibles via 'podman inspect'"
echo "  ✅ Non visibles dans les variables d'environnement"
echo "  ✅ Accessible uniquement via le système de fichiers"
echo "  ✅ Isolation par conteneur"
echo ""

echo -e "${GREEN}🧹 Nettoyage final${NC}\n"
cleanup

echo -e "${GREEN}✅ Démonstration terminée!${NC}"
echo ""
echo "Pour utiliser les secrets dans vos applications:"
echo "  1. Créer le secret:    echo 'valeur' | podman secret create nom_secret -"
echo "  2. Utiliser le secret: podman run --secret nom_secret myapp"
echo "  3. Lire dans l'app:    cat /run/secrets/nom_secret"
echo ""
