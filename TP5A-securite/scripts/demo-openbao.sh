#!/bin/bash
#
# Script de démonstration OpenBao
# Gestionnaire de secrets open-source (fork de Vault)
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Démonstration OpenBao ===${NC}"
echo -e "${CYAN}Gestionnaire de secrets 100% open-source (MPL 2.0)${NC}\n"

# Variables
OPENBAO_ADDR="http://localhost:8200"
OPENBAO_TOKEN="demo-root-token"
CONTAINER_NAME="openbao-demo"

# Fonction de nettoyage
cleanup() {
    echo -e "\n${YELLOW}Nettoyage...${NC}"
    podman rm -f $CONTAINER_NAME 2>/dev/null || true
}

# Nettoyer au démarrage
cleanup

# Vérifier si le CLI bao est installé
if ! command -v bao &> /dev/null; then
    echo -e "${YELLOW}⚠️  Le CLI 'bao' n'est pas installé${NC}"
    echo "Utilisation de podman exec à la place..."
    BAO_CMD="podman exec -e BAO_ADDR=$OPENBAO_ADDR -e BAO_TOKEN=$OPENBAO_TOKEN $CONTAINER_NAME bao"
else
    export BAO_ADDR=$OPENBAO_ADDR
    export BAO_TOKEN=$OPENBAO_TOKEN
    BAO_CMD="bao"
fi

echo -e "${GREEN}🚀 Étape 1: Lancement d'OpenBao (mode dev)${NC}\n"

podman run -d \
    --name $CONTAINER_NAME \
    -p 8200:8200 \
    -e BAO_DEV_ROOT_TOKEN_ID=$OPENBAO_TOKEN \
    -e BAO_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
    --cap-add IPC_LOCK \
    quay.io/openbao/openbao:latest server -dev

echo -e "${GREEN}✅ OpenBao démarré${NC}"

# Attendre qu'OpenBao soit prêt
echo -e "\n${YELLOW}Attente de la disponibilité d'OpenBao...${NC}"
for i in {1..30}; do
    if curl -s $OPENBAO_ADDR/v1/sys/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OpenBao est prêt!${NC}\n"
        break
    fi
    sleep 1
done

echo -e "${GREEN}📊 Étape 2: Informations système${NC}\n"
$BAO_CMD status

echo -e "\n${GREEN}🔐 Étape 3: Activation du moteur de secrets KV v2${NC}\n"
$BAO_CMD secrets enable -version=2 kv 2>/dev/null || echo "KV déjà activé"

echo -e "\n${GREEN}💾 Étape 4: Création de secrets${NC}\n"

# Générer un mot de passe sécurisé
DB_PASSWORD=$(openssl rand -base64 32)
API_KEY=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Créer les secrets
echo "Création des secrets pour une application..."

$BAO_CMD kv put kv/demo/database \
    host="postgres.example.com" \
    port="5432" \
    username="appuser" \
    password="$DB_PASSWORD" \
    database="myapp"

echo -e "${GREEN}✅ Secret database créé${NC}"

$BAO_CMD kv put kv/demo/api \
    endpoint="https://api.example.com" \
    key="$API_KEY"

echo -e "${GREEN}✅ Secret API créé${NC}"

$BAO_CMD kv put kv/demo/jwt \
    algorithm="HS256" \
    secret="$JWT_SECRET"

echo -e "${GREEN}✅ Secret JWT créé${NC}"

echo -e "\n${GREEN}📋 Étape 5: Liste des secrets${NC}\n"
$BAO_CMD kv list kv/demo/

echo -e "\n${GREEN}🔍 Étape 6: Lecture des secrets${NC}\n"

echo -e "${CYAN}Secret database (format table):${NC}"
$BAO_CMD kv get kv/demo/database

echo -e "\n${CYAN}Secret API (format JSON):${NC}"
$BAO_CMD kv get -format=json kv/demo/api | jq .

echo -e "\n${CYAN}Récupération d'un champ spécifique:${NC}"
echo "Password: $($BAO_CMD kv get -field=password kv/demo/database)"

echo -e "\n${GREEN}🔄 Étape 7: Versioning des secrets${NC}\n"

echo "Modification du mot de passe..."
NEW_PASSWORD=$(openssl rand -base64 32)
$BAO_CMD kv put kv/demo/database \
    host="postgres.example.com" \
    port="5432" \
    username="appuser" \
    password="$NEW_PASSWORD" \
    database="myapp"

echo -e "\n${CYAN}Récupération de la version 1 (ancien mot de passe):${NC}"
OLD_PASS=$($BAO_CMD kv get -version=1 -field=password kv/demo/database)
echo "Version 1: $OLD_PASS"

echo -e "\n${CYAN}Récupération de la version 2 (nouveau mot de passe):${NC}"
NEW_PASS=$($BAO_CMD kv get -version=2 -field=password kv/demo/database)
echo "Version 2: $NEW_PASS"

echo -e "\n${GREEN}🔒 Étape 8: Politiques d'accès${NC}\n"

# Créer une politique en lecture seule
podman exec $CONTAINER_NAME sh -c "cat > /tmp/readonly.hcl <<EOF
path \"kv/data/demo/*\" {
  capabilities = [\"read\", \"list\"]
}
EOF"

$BAO_CMD policy write demo-readonly /tmp/readonly.hcl

echo -e "${GREEN}✅ Politique 'demo-readonly' créée${NC}"

# Créer un token avec cette politique
echo -e "\nCréation d'un token avec la politique..."
READONLY_TOKEN=$($BAO_CMD token create \
    -policy=demo-readonly \
    -ttl=1h \
    -format=json | jq -r .auth.client_token)

echo "Token en lecture seule: $READONLY_TOKEN"

echo -e "\n${GREEN}🧪 Étape 9: Test de la politique${NC}\n"

# Tester avec le token readonly
echo "Test de lecture avec le token readonly..."
BAO_TOKEN=$READONLY_TOKEN $BAO_CMD kv get kv/demo/database > /dev/null && \
    echo -e "${GREEN}✅ Lecture autorisée${NC}"

echo -e "\nTest d'écriture avec le token readonly..."
if BAO_TOKEN=$READONLY_TOKEN $BAO_CMD kv put kv/demo/test value="test" 2>/dev/null; then
    echo -e "${RED}❌ Écriture autorisée (ne devrait pas!)${NC}"
else
    echo -e "${GREEN}✅ Écriture refusée (attendu)${NC}"
fi

echo -e "\n${GREEN}🐳 Étape 10: Intégration avec Podman Secrets${NC}\n"

echo "Récupération du mot de passe depuis OpenBao..."
RETRIEVED_PASSWORD=$($BAO_CMD kv get -field=password kv/demo/database)

echo "Création d'un Podman Secret..."
echo "$RETRIEVED_PASSWORD" | podman secret create demo_db_password - 2>/dev/null || \
    echo "Secret déjà existant"

echo -e "\n${CYAN}Lancement d'un conteneur avec le secret:${NC}"
podman run --rm --secret demo_db_password alpine sh -c '
    echo "✅ Secret monté à: /run/secrets/demo_db_password"
    echo "Permissions: $(ls -l /run/secrets/demo_db_password)"
    echo "Longueur du secret: $(wc -c < /run/secrets/demo_db_password) caractères"
'

# Nettoyer le secret Podman
podman secret rm demo_db_password 2>/dev/null || true

echo -e "\n${GREEN}📊 Étape 11: Comparaison avec HashiCorp Vault${NC}\n"

cat << EOF
┌─────────────────────────────────────────────────────────────────┐
│               OpenBao vs HashiCorp Vault                        │
├─────────────────────────┬───────────────┬───────────────────────┤
│ Critère                 │ Vault         │ OpenBao               │
├─────────────────────────┼───────────────┼───────────────────────┤
│ Licence                 │ BSL 1.1       │ MPL 2.0 (permissive)  │
│ Open Source             │ ❌ Source     │ ✅ Vraiment OS        │
│ Gouvernance             │ HashiCorp     │ Linux Foundation      │
│ Compatibilité API       │ Originale     │ ✅ Compatible         │
│ Coût                    │ Gratuit/Payant│ ✅ Toujours gratuit   │
│ Développement           │ Fermé         │ ✅ Communautaire      │
│ Support commercial      │ ✅ Officiel   │ Tiers                 │
└─────────────────────────┴───────────────┴───────────────────────┘
EOF

echo -e "\n${GREEN}✅ Avantages d'OpenBao:${NC}"
echo "  ✅ 100% Open Source (MPL 2.0)"
echo "  ✅ Gouvernance communautaire (Linux Foundation)"
echo "  ✅ Compatible avec l'écosystème Vault existant"
echo "  ✅ Pas de restrictions de licence"
echo "  ✅ Migration facile depuis Vault"

echo -e "\n${GREEN}🎯 Cas d'usage recommandés:${NC}"
echo "  • Organisations préférant l'open source pur"
echo "  • Projets nécessitant une licence permissive"
echo "  • Environnements on-premise sans support commercial"
echo "  • Migration depuis Vault (versions < 1.14)"

echo -e "\n${BLUE}=== Démonstration terminée! ===${NC}\n"

echo "OpenBao continue de tourner. Pour interagir:"
echo -e "${CYAN}export BAO_ADDR=$OPENBAO_ADDR${NC}"
echo -e "${CYAN}export BAO_TOKEN=$OPENBAO_TOKEN${NC}"
echo -e "${CYAN}podman exec -it $CONTAINER_NAME bao status${NC}"

echo -e "\nPour arrêter:"
echo -e "${CYAN}podman rm -f $CONTAINER_NAME${NC}"

echo -e "\n${YELLOW}Pour un exemple complet avec Podman Compose:${NC}"
echo -e "${CYAN}cd exemples${NC}"
echo -e "${CYAN}podman-compose -f openbao-compose.yaml up -d${NC}"
