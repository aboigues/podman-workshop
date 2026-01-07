#!/bin/sh
#
# Script d'initialisation OpenBao
# Configure les secrets et les politiques au démarrage
#

set -e

echo "=== Initialisation OpenBao ==="

# Attendre qu'OpenBao soit prêt
echo "Attente de la disponibilité d'OpenBao..."
until wget --spider -q http://openbao:8200/v1/sys/health 2>/dev/null; do
    echo "OpenBao n'est pas encore prêt, attente..."
    sleep 2
done

echo "✅ OpenBao est prêt!"

# Activer le moteur KV v2
echo "Activation du moteur de secrets KV v2..."
bao secrets enable -version=2 kv 2>/dev/null || echo "KV déjà activé"

# Créer les secrets pour l'application
echo "Création des secrets pour l'application..."

# Secrets de base de données
bao kv put kv/myapp/database \
    username="appuser" \
    password="$(openssl rand -base64 32)" \
    host="postgres" \
    port="5432" \
    database="appdb"

# Clé API
bao kv put kv/myapp/api \
    key="$(openssl rand -base64 32)" \
    endpoint="https://api.example.com"

# Autres secrets
bao kv put kv/myapp/jwt \
    secret="$(openssl rand -base64 64)" \
    algorithm="HS256"

echo "✅ Secrets créés avec succès!"

# Créer une politique en lecture seule pour l'application
echo "Création de la politique d'accès..."

cat > /tmp/app-policy.hcl <<EOF
# Politique pour l'application
# Lecture seule sur les secrets de myapp
path "kv/data/myapp/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

bao policy write app-readonly /tmp/app-policy.hcl

echo "✅ Politique créée!"

# Créer un token avec la politique (pour production)
# En dev, on utilise le root token
echo "Création d'un token applicatif..."
APP_TOKEN=$(bao token create \
    -policy=app-readonly \
    -period=24h \
    -display-name="app-token" \
    -format=json | grep -o '"client_token":"[^"]*"' | cut -d'"' -f4)

echo "Token applicatif créé: $APP_TOKEN"
echo "En production, utilisez ce token au lieu du root token!"

# Lister les secrets créés
echo ""
echo "📋 Secrets disponibles:"
bao kv list kv/myapp/

echo ""
echo "✅ Initialisation terminée!"
echo ""
echo "Pour tester:"
echo "  bao kv get kv/myapp/database"
echo "  bao kv get kv/myapp/api"
echo "  bao kv get kv/myapp/jwt"
