# Exemples de gestion des secrets avec Podman

Ce dossier contient des exemples pratiques démontrant comment gérer les secrets de manière sécurisée avec Podman.

## 📁 Fichiers

### Applications
- **`app-with-secrets.py`** : Application Python démontrant la lecture sécurisée des secrets
- **`Dockerfile-secrets`** : Dockerfile sécurisé pour l'application
- **`Dockerfile-secure`** : Exemple de Dockerfile avec utilisateur non-root (existant)

### Configuration
- **`compose-secrets.yaml`** : Exemple complet d'architecture multi-services avec secrets
- **`seccomp-profile.json`** : Profil Seccomp restrictif pour renforcer la sécurité

### Scripts
- **`../scripts/demo-secrets.sh`** : Script de démonstration interactive des secrets Podman

---

## 🚀 Utilisation rapide

### 1. Démonstration simple

```bash
# Lancer la démonstration complète
cd ../scripts
chmod +x demo-secrets.sh
./demo-secrets.sh
```

Ce script va :
- ✅ Créer des secrets Podman
- ✅ Construire une image de démonstration
- ✅ Lancer un conteneur avec secrets
- ✅ Démontrer la sécurité (secrets non visibles via inspect/env)
- ✅ Comparer avec les variables d'environnement

### 2. Utilisation manuelle

```bash
# Créer les secrets
echo "my_db_password" | podman secret create db_password -
echo "my_api_key" | podman secret create api_key -

# Construire l'image
podman build -t secure-app:latest -f Dockerfile-secrets .

# Lancer le conteneur avec secrets
podman run --rm \
  --secret db_password \
  --secret api_key \
  secure-app:latest
```

### 3. Avec Compose (architecture complète)

```bash
# Créer tous les secrets nécessaires
echo "postgres_secure_password" | podman secret create db_password -
echo "api_key_secret_xyz" | podman secret create api_key -
echo "redis_secure_password" | podman secret create redis_password -

# Lancer l'architecture complète
podman-compose -f compose-secrets.yaml up -d

# Vérifier les logs
podman-compose -f compose-secrets.yaml logs -f app

# Arrêter
podman-compose -f compose-secrets.yaml down
```

---

## 🔒 Fonctionnalités de sécurité démontrées

### Podman Secrets
- ✅ **Stockage chiffré** par Podman
- ✅ **Montage en tmpfs** (RAM uniquement, jamais sur disque)
- ✅ **Permissions 400** automatiques
- ✅ **Isolation** : secrets accessibles uniquement au conteneur ciblé
- ✅ **Non visibles** via `podman inspect`
- ✅ **Non visibles** dans les variables d'environnement

### Profil Seccomp
Le fichier `seccomp-profile.json` limite les appels système disponibles :
- ✅ Réduit la surface d'attaque
- ✅ Empêche les opérations dangereuses
- ✅ Autorise uniquement les syscalls nécessaires

### Sécurité du conteneur
Le `compose-secrets.yaml` montre :
- ✅ **Utilisateurs non-root** (`user: 1001`, `user: postgres`, etc.)
- ✅ **Système de fichiers en lecture seule** (`read_only: true`)
- ✅ **Capabilities minimales** (`cap_drop: ALL` + ajouts ciblés)
- ✅ **Empêcher l'escalade** (`no-new-privileges:true`)
- ✅ **Limites de ressources** (mémoire, CPU, PIDs)
- ✅ **Tmpfs pour /tmp et /run**
- ✅ **SELinux** (`:Z` sur les volumes)

---

## 📊 Comparaison : Variables d'env vs Secrets

### ❌ Variables d'environnement (INSÉCURE)

```bash
podman run -e DB_PASSWORD="password123" myapp
```

**Problèmes :**
- Visible dans `podman inspect`
- Visible dans `/proc/[PID]/environ`
- Peut apparaître dans les logs
- Hérité par les processus enfants
- Stocké en clair
- Pas de rotation facile

### ✅ Podman Secrets (SÉCURISÉ)

```bash
echo "password123" | podman secret create db_password -
podman run --secret db_password myapp
```

**Avantages :**
- Stockage chiffré
- Montage en tmpfs (RAM)
- Permissions strictes (400)
- Non visible via inspect
- Non visible dans env
- Rotation simplifiée
- Audit trail

---

## 🧪 Tests de sécurité

### Vérifier qu'un secret n'est PAS visible

```bash
# Créer et lancer un conteneur
echo "test_secret" | podman secret create test -
podman run -d --name test --secret test nginx

# Test 1: Secret non visible dans inspect
podman inspect test | grep -i "test_secret"
# Devrait retourner : (rien)

# Test 2: Secret non visible dans les env
podman exec test env | grep -i secret
# Devrait retourner : (rien)

# Test 3: Secret accessible via fichier
podman exec test cat /run/secrets/test
# Devrait retourner : test_secret

# Test 4: Vérifier les permissions
podman exec test ls -l /run/secrets/test
# Devrait retourner : -r-------- (400)

# Nettoyage
podman rm -f test
podman secret rm test
```

---

## 🎯 Bonnes pratiques

### 1. Créer des secrets

```bash
# Depuis stdin (recommandé)
echo "my_secret" | podman secret create secret_name -

# Depuis un fichier
podman secret create secret_name /path/to/secret_file

# Générer un secret aléatoire
openssl rand -base64 32 | podman secret create random_secret -
```

### 2. Lister et gérer

```bash
# Lister tous les secrets
podman secret ls

# Inspecter (ne montre PAS le contenu)
podman secret inspect secret_name

# Supprimer
podman secret rm secret_name
```

### 3. Rotation des secrets

```bash
# 1. Créer un nouveau secret
echo "new_password" | podman secret create db_password_v2 -

# 2. Mettre à jour le conteneur pour utiliser le nouveau
podman run --secret db_password_v2,target=/run/secrets/db_password myapp

# 3. Supprimer l'ancien secret (après migration)
podman secret rm db_password
```

### 4. Dans le code application

```python
# Python : Fonction réutilisable
from pathlib import Path

def read_secret(name: str) -> str:
    secret_path = Path(f'/run/secrets/{name}')
    if not secret_path.exists():
        raise FileNotFoundError(f"Secret {name} not found")
    return secret_path.read_text().strip()

# Usage
db_password = read_secret('db_password')
api_key = read_secret('api_key')
```

---

### 4. Avec OpenBao (gestionnaire externe open-source)

OpenBao est un fork 100% open-source de HashiCorp Vault, maintenu par la Linux Foundation.

```bash
# Lancer la démonstration complète
cd ../scripts
chmod +x demo-openbao.sh
./demo-openbao.sh
```

**Ou manuellement :**

```bash
# Lancer OpenBao en mode dev
podman run -d \
  --name openbao-dev \
  -p 8200:8200 \
  -e BAO_DEV_ROOT_TOKEN_ID=dev-token \
  --cap-add IPC_LOCK \
  quay.io/openbao/openbao:latest server -dev

# Configurer le client
export BAO_ADDR='http://localhost:8200'
export BAO_TOKEN='dev-token'

# Créer des secrets
podman exec openbao-dev bao secrets enable -version=2 kv
podman exec -e BAO_ADDR -e BAO_TOKEN openbao-dev \
  bao kv put kv/myapp/db password="secure_pass" username="dbuser"

# Récupérer et injecter dans Podman
PASSWORD=$(podman exec -e BAO_ADDR -e BAO_TOKEN openbao-dev \
  bao kv get -field=password kv/myapp/db)
echo "$PASSWORD" | podman secret create db_password -

# Lancer l'application
podman run --secret db_password myapp
```

**Architecture complète avec Compose :**

```bash
# Voir openbao-compose.yaml pour un exemple complet
podman-compose -f openbao-compose.yaml up -d
```

**Avantages d'OpenBao :**
- ✅ 100% Open Source (MPL 2.0)
- ✅ Compatible API Vault (migration facile)
- ✅ Gouvernance communautaire (Linux Foundation)
- ✅ Rotation automatique des secrets
- ✅ Versioning et audit trail
- ✅ Politiques d'accès granulaires
- ✅ Gratuit pour tous les cas d'usage

---

## 📚 Ressources

- [Documentation Podman Secrets](https://docs.podman.io/en/latest/markdown/podman-secret.1.html)
- [OpenBao Official Site](https://openbao.org/)
- [OpenBao Documentation](https://openbao.org/docs/)
- [OpenBao GitHub](https://github.com/openbao/openbao)
- [Bonnes pratiques sécurité conteneurs](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Seccomp profiles](https://docs.docker.com/engine/security/seccomp/)
- [Guide principal TP5A](../README.md)

---

## 🆘 Dépannage

### Erreur : secret not found

```bash
# Vérifier que le secret existe
podman secret ls

# Créer le secret s'il n'existe pas
echo "value" | podman secret create name -
```

### Erreur : permission denied sur /run/secrets

```bash
# Vérifier l'utilisateur du conteneur
podman exec container_name id

# Les secrets sont accessibles uniquement par l'utilisateur du processus principal
```

### Secret vide ou malformé

```bash
# Ne pas ajouter de retour à la ligne
echo -n "secret_value" | podman secret create name -

# Vérifier le contenu (depuis le conteneur)
podman exec container_name cat /run/secrets/name | xxd
```
