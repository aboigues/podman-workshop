# TP5A - Sécurité avec Podman

## Objectifs
- Maîtriser le mode rootless et comprendre ses avantages de sécurité
- Gérer les capabilities Linux pour limiter les privilèges des conteneurs
- Configurer SELinux et AppArmor pour renforcer l'isolation
- Scanner les images pour détecter les vulnérabilités
- Créer des images sécurisées avec utilisateurs non-root
- Implémenter les bonnes pratiques de sécurité des conteneurs
- Gérer les secrets et informations sensibles
- Limiter les ressources pour éviter les abus

## Prérequis
- Podman installé (mode rootless recommandé)
- Accès terminal
- Connaissances de base sur Linux et les conteneurs
- Outils de scan (Trivy) - optionnel

## Démarrage rapide

```bash
# Vérifier le mode rootless
./scripts/test-rootless.sh

# Scanner une image
./scripts/scan-image.sh nginx:alpine

# Tester les capabilities
./scripts/test-capabilities.sh

# Construire une image sécurisée
cd exemples
podman build -t secure-app -f Dockerfile-secure .
```

---

## Introduction à la sécurité des conteneurs

La sécurité des conteneurs repose sur plusieurs couches de protection :

### Principes fondamentaux

1. **Isolation** : Séparation des processus et ressources
2. **Principe du moindre privilège** : Donner uniquement les permissions nécessaires
3. **Défense en profondeur** : Multiples couches de sécurité
4. **Sécurité par défaut** : Configuration sécurisée dès le départ

### Avantages de Podman pour la sécurité

- **Sans daemon** : Pas de processus privilégié central à compromettre
- **Rootless par défaut** : Exécution sans privilèges root
- **SELinux natif** : Intégration complète avec SELinux
- **Fork/exec model** : Pas de daemon intermédiaire
- **User namespaces** : Isolation complète des utilisateurs

---

## Mode Rootless

### Qu'est-ce que le mode rootless ?

Le mode rootless permet d'exécuter des conteneurs **sans privilèges root**, augmentant considérablement la sécurité.

### Avantages du mode rootless

✅ **Sécurité renforcée** : Un conteneur compromis ne peut pas affecter le système hôte
✅ **Isolation utilisateur** : Chaque utilisateur a ses propres conteneurs isolés
✅ **Pas besoin de sudo** : Pas de risque d'escalade de privilèges
✅ **Multi-tenancy** : Plusieurs utilisateurs peuvent utiliser Podman en toute sécurité
✅ **Conformité** : Respect des politiques de sécurité strictes

### Vérifier le mode rootless

```bash
# Vérifier si Podman s'exécute en mode rootless
podman system info | grep runAsUser

# Voir le mapping des utilisateurs
podman unshare cat /proc/self/uid_map
podman unshare cat /proc/self/gid_map

# Vérifier l'utilisateur dans un conteneur
podman run --rm alpine id
```

#### Explications du mapping utilisateur

**User namespaces** permet de mapper les UID/GID du conteneur vers des UID/GID différents sur l'hôte.

Exemple de mapping :
```
         0       1000          1
         1     100000      65536
```

- Ligne 1 : UID 0 (root) dans le conteneur → UID 1000 sur l'hôte (votre utilisateur)
- Ligne 2 : UID 1-65536 dans le conteneur → UID 100000-165536 sur l'hôte (sous-UID)

**Conséquence** : Même si un processus est root dans le conteneur, il n'a pas de privilèges sur l'hôte.

### Configuration du mode rootless

#### Fichiers de configuration importants

**`/etc/subuid` et `/etc/subgid`**

Définissent les plages d'UID/GID subordonnés pour chaque utilisateur :

```bash
# Voir vos sub-UIDs
cat /etc/subuid | grep $USER

# Voir vos sub-GIDs
cat /etc/subgid | grep $USER

# Format : utilisateur:premier_uid:nombre
# Exemple : john:100000:65536
```

#### Commandes de gestion rootless

```bash
# Migrer vers rootless si vous utilisez root
podman system migrate

# Réinitialiser les namespaces utilisateur
podman system reset

# Voir les informations rootless
podman info --format '{{.Host.Security.Rootless}}'
```

### Limitations du mode rootless

⚠️ **Ports privilégiés (< 1024)**
- Solution : Mapper vers des ports > 1024 sur l'hôte
```bash
# Utiliser le port 8080 au lieu de 80
podman run -p 8080:80 nginx
```

⚠️ **Volumes avec permissions**
- Solution : Utiliser `:Z` ou `:z` pour SELinux
```bash
podman run -v ./data:/data:Z nginx
```

⚠️ **Performance réseau légèrement réduite**
- Mode rootless utilise slirp4netns par défaut
- Alternative : pasta (plus performant, Podman 4.4+)

---

## Capabilities Linux

### Qu'est-ce qu'une capability ?

Les **capabilities** Linux divisent les privilèges root en unités distinctes qui peuvent être accordées individuellement.

### Capabilities par défaut de Podman

Podman accorde un ensemble minimal de capabilities :

```bash
# Voir les capabilities d'un conteneur
podman run --rm alpine sh -c 'cat /proc/self/status | grep Cap'

# Liste lisible des capabilities
podman run --rm alpine capsh --print
```

### Capabilities courantes

| Capability | Description | Risque |
|------------|-------------|--------|
| `CAP_CHOWN` | Changer propriétaire des fichiers | Faible |
| `CAP_NET_BIND_SERVICE` | Binder sur ports < 1024 | Faible |
| `CAP_NET_RAW` | Créer des sockets raw | Moyen |
| `CAP_SYS_ADMIN` | Administration système | **ÉLEVÉ** |
| `CAP_SYS_PTRACE` | Tracer des processus | Élevé |
| `CAP_SYS_MODULE` | Charger des modules kernel | **CRITIQUE** |
| `CAP_DAC_OVERRIDE` | Outrepasser permissions fichiers | Élevé |

### Retirer des capabilities (DROP)

```bash
# Retirer toutes les capabilities
podman run --cap-drop=ALL nginx

# Retirer des capabilities spécifiques
podman run --cap-drop=NET_RAW --cap-drop=CHOWN nginx

# Retirer toutes sauf certaines
podman run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx
```

### Ajouter des capabilities (ADD)

```bash
# Ajouter une capability spécifique
podman run --cap-add=SYS_TIME alpine date -s "2024-01-01"

# Ajouter plusieurs capabilities
podman run --cap-add=NET_ADMIN --cap-add=NET_RAW network-tool
```

⚠️ **Attention** : N'ajoutez des capabilities que si absolument nécessaire !

### Conteneur privilégié (à éviter)

```bash
# Mode privilégié (TOUTES les capabilities + accès devices)
podman run --privileged nginx

# ⚠️ DANGEREUX : Équivalent à donner accès root au système
```

**Alternatives au mode privilégié :**
1. Identifier la capability exacte nécessaire
2. N'accorder que cette capability avec `--cap-add`
3. Utiliser `--device` pour monter un device spécifique

---

## SELinux et AppArmor

### SELinux (Security-Enhanced Linux)

SELinux ajoute une couche de contrôle d'accès obligatoire (MAC) au niveau du kernel.

#### Vérifier l'état de SELinux

```bash
# Vérifier si SELinux est activé
getenforce

# Voir le contexte SELinux actuel
id -Z

# Voir le contexte d'un fichier
ls -Z /path/to/file

# Voir le contexte d'un processus
ps -eZ | grep podman
```

#### Contextes SELinux avec Podman

**`:Z` (private unshared label)**
- Applique un label SELinux unique au volume
- Le volume est accessible **uniquement** par ce conteneur
- **Recommandé** pour les volumes contenant des données sensibles

```bash
podman run -v ./data:/data:Z nginx
```

**`:z` (shared label)**
- Applique un label SELinux partagé
- Le volume peut être partagé entre **plusieurs conteneurs**
- Utilisé pour les volumes partagés

```bash
podman run -v ./shared:/data:z nginx
podman run -v ./shared:/data:z redis
```

#### Désactiver SELinux (déconseillé)

```bash
# Désactiver uniquement pour un conteneur
podman run --security-opt label=disable nginx

# ⚠️ Réduit considérablement la sécurité !
```

### AppArmor

AppArmor est une alternative à SELinux, utilisée sur Ubuntu et Debian.

#### Profils AppArmor

```bash
# Lister les profils chargés
sudo aa-status

# Voir le profil d'un processus
cat /proc/$(pidof podman)/attr/current

# Charger un profil
sudo apparmor_parser -r /etc/apparmor.d/podman-default
```

#### Utiliser un profil AppArmor personnalisé

```bash
# Charger le profil
sudo apparmor_parser -r /path/to/custom-profile

# Utiliser le profil
podman run --security-opt apparmor=custom-profile nginx
```

---

## Scan de vulnérabilités

### Pourquoi scanner les images ?

- Détecter les CVE (Common Vulnerabilities and Exposures)
- Identifier les packages obsolètes
- Vérifier les mauvaises configurations
- Conformité et audit de sécurité

### Outils de scan

#### Trivy (Recommandé)

**Installation :**

```bash
# Via package manager (Fedora/RHEL)
sudo dnf install trivy

# Via script
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Via conteneur (sans installation)
alias trivy='podman run --rm -v /var/run/podman/podman.sock:/var/run/podman/podman.sock aquasec/trivy'
```

**Utilisation :**

```bash
# Scanner une image locale
trivy image nginx:alpine

# Scanner avec severité minimale
trivy image --severity HIGH,CRITICAL nginx:alpine

# Format JSON pour automatisation
trivy image --format json --output result.json nginx:alpine

# Scanner un Dockerfile
trivy config Dockerfile

# Scanner le système de fichiers
trivy fs ./

# Ignorer les CVE non corrigées
trivy image --ignore-unfixed nginx:alpine
```

#### Clair

```bash
# Lancer Clair (base de données + scanner)
podman run -d --name clair-db postgres
podman run -d --name clair --link clair-db:postgres arminc/clair-local-scan

# Scanner une image
clairctl analyze -l image nginx:alpine
```

#### Grype

```bash
# Installation
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Scanner une image
grype nginx:alpine

# Format de sortie
grype -o json nginx:alpine
```

### Automatisation du scan

**Script de scan automatique :**

```bash
#!/bin/bash
# scan-all-images.sh

SEVERITY="HIGH,CRITICAL"

echo "=== Scan de toutes les images locales ==="

podman images --format "{{.Repository}}:{{.Tag}}" | while read image; do
    if [ "$image" != "<none>:<none>" ]; then
        echo ""
        echo "📦 Scan de : $image"
        trivy image --severity $SEVERITY --quiet $image
    fi
done
```

### Intégration CI/CD

**Pipeline GitLab CI :**

```yaml
security-scan:
  stage: test
  image: aquasec/trivy:latest
  script:
    - trivy image --exit-code 1 --severity CRITICAL $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - merge_requests
    - main
```

---

## Images sécurisées

### Utiliser des utilisateurs non-root

#### Dockerfile sécurisé

```dockerfile
FROM python:3.11-slim

# Créer un utilisateur non-root
RUN useradd -m -u 1001 -s /bin/bash appuser

WORKDIR /app

# Installer les dépendances (en root)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier l'application
COPY app.py .

# Changer le propriétaire
RUN chown -R appuser:appuser /app

# Passer à l'utilisateur non-root
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
```

#### Explications

**`RUN useradd -m -u 1001 -s /bin/bash appuser`**
- `-m` : Crée le répertoire home
- `-u 1001` : UID explicite (évite les conflits)
- `-s /bin/bash` : Shell par défaut
- Éviter l'UID 0 (root) et les UID système (1-999)

**`USER appuser`**
- Tous les processus suivants s'exécutent avec cet utilisateur
- À placer APRÈS les opérations nécessitant root
- Les ports < 1024 ne seront plus accessibles

**`RUN chown -R appuser:appuser /app`**
- Change le propriétaire des fichiers
- Nécessaire car COPY s'exécute en root
- Permet à l'utilisateur d'écrire dans le répertoire

### Images de base minimales

```dockerfile
# ❌ Mauvais : Image complète
FROM ubuntu:22.04

# ✅ Bon : Image minimale
FROM ubuntu:22.04-minimal

# ✅ Meilleur : Image distroless
FROM gcr.io/distroless/python3

# ✅ Optimal : Scratch (binaire statique uniquement)
FROM scratch
COPY app /app
CMD ["/app"]
```

### Multi-stage builds pour la sécurité

```dockerfile
# Stage 1 : Build
FROM golang:1.21 AS builder
WORKDIR /build
COPY . .
RUN CGO_ENABLED=0 go build -o app

# Stage 2 : Runtime minimal
FROM scratch
COPY --from=builder /build/app /app
USER 1001
CMD ["/app"]
```

**Avantages :**
- Image finale ne contient que le binaire
- Pas d'outils de build dans l'image de production
- Surface d'attaque minimale

---

## Gestion des secrets

### ❌ À NE PAS FAIRE

```dockerfile
# Mauvais : Secret en clair dans l'image
ENV API_KEY=super_secret_key_123

# Mauvais : Fichier de configuration avec secrets
COPY config-with-secrets.yaml /app/config.yaml

# Mauvais : Secret dans l'historique des commandes
podman run -e DB_PASSWORD=motdepasse123 myapp
```

### 🔐 Hiérarchie des solutions (de la moins à la plus sécurisée)

#### Niveau 1 : Variables d'environnement (⚠️ À éviter)

**Pourquoi c'est problématique :**

```bash
# Les variables sont visibles dans l'inspection
podman inspect myapp | grep -i password

# Visibles dans les processus
cat /proc/$(pidof myapp)/environ

# Apparaissent dans les logs système
podman logs myapp  # Peut exposer les secrets

# Héritées par tous les processus enfants
# Aucune rotation automatique possible
```

**Si vous devez absolument les utiliser :**

```bash
# ⚠️ Moins mauvais : Via fichier env avec permissions strictes
echo "API_KEY=secret123" > .env
chmod 600 .env
podman run --env-file .env myapp
rm .env  # Supprimer immédiatement après

# ⚠️ Jamais dans l'historique shell
export API_KEY="secret123"
podman run -e API_KEY myapp
unset API_KEY
```

**Risques :**
- ❌ Exposition via `podman inspect`
- ❌ Visible dans `/proc/[PID]/environ`
- ❌ Logs accidentels
- ❌ Héritage par processus enfants
- ❌ Pas de rotation
- ❌ Stockage en clair

---

#### Niveau 2 : Volumes montés (⭐ Acceptable)

```bash
# Créer le fichier de secrets avec permissions restreintes
echo "password123" > /secure/secrets.txt
chmod 600 /secure/secrets.txt
chown 1001:1001 /secure/secrets.txt  # UID de l'utilisateur du conteneur

# Monter en lecture seule avec SELinux
podman run \
  -v /secure/secrets.txt:/run/secrets/password:ro,Z \
  --user 1001 \
  myapp
```

**Dans l'application :**

```python
# Python - Lecture sécurisée
import os
from pathlib import Path

SECRET_FILE = Path('/run/secrets/password')
if SECRET_FILE.exists():
    password = SECRET_FILE.read_text().strip()
else:
    raise ValueError("Secret file not found")
```

**Avantages :**
- ✅ Pas visible via `podman inspect`
- ✅ Permissions Unix strictes
- ✅ SELinux/AppArmor applicable
- ✅ Lecture seule possible

**Limites :**
- ⚠️ Fichier sur le disque hôte
- ⚠️ Rotation manuelle nécessaire

---

#### Niveau 3 : Podman Secrets (⭐⭐ Recommandé)

**La meilleure solution native Podman** (Podman 3.1+)

```bash
# Créer un secret depuis stdin
echo "my_secret_password" | podman secret create db_password -

# Créer depuis un fichier
podman secret create api_key /path/to/secret_file

# Lister les secrets
podman secret ls

# Inspecter (ne montre PAS le contenu)
podman secret inspect db_password

# Utiliser le secret dans un conteneur
podman run --secret db_password myapp

# Utiliser avec un nom personnalisé dans le conteneur
podman run --secret db_password,target=/app/config/db_pass myapp

# Supprimer un secret
podman secret rm db_password
```

**Dans le conteneur, les secrets sont montés à :**
- `/run/secrets/[SECRET_NAME]` (par défaut)
- Ou le chemin spécifié avec `target=`

**Code application :**

```python
# Python - Lecture des secrets Podman
from pathlib import Path

def read_secret(secret_name: str) -> str:
    """Lit un secret Podman de manière sécurisée"""
    secret_path = Path(f'/run/secrets/{secret_name}')

    if not secret_path.exists():
        raise FileNotFoundError(f"Secret {secret_name} not found")

    # Vérifier les permissions (doit être 400 ou 600)
    stat_info = secret_path.stat()
    if stat_info.st_mode & 0o077:
        raise PermissionError(f"Secret {secret_name} has insecure permissions")

    return secret_path.read_text().strip()

# Usage
db_password = read_secret('db_password')
api_key = read_secret('api_key')
```

```javascript
// Node.js - Lecture des secrets Podman
const fs = require('fs');
const path = require('path');

function readSecret(secretName) {
    const secretPath = path.join('/run/secrets', secretName);

    if (!fs.existsSync(secretPath)) {
        throw new Error(`Secret ${secretName} not found`);
    }

    return fs.readFileSync(secretPath, 'utf8').trim();
}

// Usage
const dbPassword = readSecret('db_password');
const apiKey = readSecret('api_key');
```

```go
// Go - Lecture des secrets Podman
package main

import (
    "os"
    "path/filepath"
    "strings"
)

func ReadSecret(secretName string) (string, error) {
    secretPath := filepath.Join("/run/secrets", secretName)

    data, err := os.ReadFile(secretPath)
    if err != nil {
        return "", err
    }

    return strings.TrimSpace(string(data)), nil
}

// Usage
func main() {
    dbPassword, err := ReadSecret("db_password")
    if err != nil {
        panic(err)
    }
}
```

**Avec Podman Compose :**

```yaml
# compose.yaml
version: '3.8'

services:
  app:
    image: myapp:latest
    secrets:
      - db_password
      - api_key
    environment:
      - DB_HOST=postgres

  postgres:
    image: postgres:15-alpine
    secrets:
      - db_password
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    external: true
  api_key:
    external: true
```

```bash
# Créer les secrets avant de lancer
echo "postgres_pass" | podman secret create db_password -
echo "api_secret_key" | podman secret create api_key -

# Lancer avec compose
podman-compose up -d
```

**Avantages :**
- ✅ Stockage chiffré par Podman
- ✅ Jamais visible via `podman inspect`
- ✅ Montés en tmpfs (RAM uniquement, jamais sur disque)
- ✅ Permissions 400 automatiques
- ✅ Rotation simplifiée
- ✅ Audit trail possible
- ✅ Compatible orchestration (Kubernetes)

---

#### Niveau 4 : Gestionnaires de secrets externes (⭐⭐⭐ Production)

**Pour les environnements de production critiques**

##### A. HashiCorp Vault

```bash
# Installation du client Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault

# Configurer l'accès Vault
export VAULT_ADDR="https://vault.example.com"
export VAULT_TOKEN="s.xxxxxxxxxxxxxxxx"

# Récupérer un secret
vault kv get -field=password secret/myapp/db

# Injecter dans Podman via script
DB_PASSWORD=$(vault kv get -field=password secret/myapp/db)
echo "$DB_PASSWORD" | podman secret create db_password -
podman run --secret db_password myapp
```

**Application avec Vault natif :**

```python
# Python avec hvac (client Vault)
import hvac
import os

client = hvac.Client(
    url=os.getenv('VAULT_ADDR'),
    token=os.getenv('VAULT_TOKEN')
)

# Récupérer le secret
secret = client.secrets.kv.v2.read_secret_version(
    path='myapp/db',
    mount_point='secret'
)

db_password = secret['data']['data']['password']
```

##### B. AWS Secrets Manager

```bash
# Installation AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Récupérer un secret
aws secretsmanager get-secret-value \
  --secret-id myapp/db_password \
  --query SecretString \
  --output text

# Injecter dans Podman
aws secretsmanager get-secret-value \
  --secret-id myapp/db_password \
  --query SecretString \
  --output text | podman secret create db_password -
```

##### C. Azure Key Vault

```bash
# Installation Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Se connecter
az login

# Récupérer un secret
az keyvault secret show \
  --vault-name mykeyvault \
  --name db-password \
  --query value -o tsv

# Injecter dans Podman
az keyvault secret show \
  --vault-name mykeyvault \
  --name db-password \
  --query value -o tsv | podman secret create db_password -
```

##### D. Google Cloud Secret Manager

```bash
# Installation gcloud
curl https://sdk.cloud.google.com | bash

# Récupérer un secret
gcloud secrets versions access latest \
  --secret="db-password"

# Injecter dans Podman
gcloud secrets versions access latest \
  --secret="db-password" | podman secret create db_password -
```

**Avantages des gestionnaires externes :**
- ✅ Chiffrement au repos et en transit
- ✅ Rotation automatique des secrets
- ✅ Audit trail complet
- ✅ Contrôle d'accès granulaire (IAM, Policies)
- ✅ Versioning des secrets
- ✅ Haute disponibilité
- ✅ Intégration CI/CD
- ✅ Conformité (PCI-DSS, HIPAA, etc.)

---

### 📋 Tableau comparatif des solutions

| Solution | Sécurité | Simplicité | Rotation | Audit | Production |
|----------|----------|------------|----------|-------|------------|
| Variables d'env | ⚠️ Faible | ✅ Très simple | ❌ Manuelle | ❌ Non | ❌ Non |
| Volumes montés | ⭐ Moyenne | ✅ Simple | ⚠️ Manuelle | ⚠️ Limitée | ⚠️ Petite échelle |
| Podman Secrets | ⭐⭐ Bonne | ✅ Simple | ✅ Simplifiée | ✅ Oui | ✅ Oui |
| Vault/Cloud | ⭐⭐⭐ Excellente | ⚠️ Complexe | ✅ Automatique | ✅ Complete | ✅ Recommandé |

---

### 🎯 Recommandations par cas d'usage

**Développement local :**
- ✅ Podman Secrets
- ⚠️ Volumes montés (acceptable)

**Tests / Staging :**
- ✅ Podman Secrets
- ✅ Vault (si disponible)

**Production :**
- ✅ Vault / AWS / Azure / GCP
- ✅ Podman Secrets (acceptable pour petites applications)

**Applications critiques (banque, santé) :**
- ✅ UNIQUEMENT gestionnaires externes (Vault, Cloud)
- ✅ Avec HSM (Hardware Security Module)
- ✅ Rotation automatique obligatoire

---

## Limitation des ressources

### Pourquoi limiter les ressources ?

- Prévenir les attaques par déni de service (DoS)
- Isoler les conteneurs entre eux
- Garantir des performances prévisibles
- Éviter la surcharge du système hôte

### Limites de mémoire

```bash
# Limite de mémoire
podman run --memory=512m nginx

# Limite mémoire + swap
podman run --memory=512m --memory-swap=1g nginx

# Réservation mémoire (garantie)
podman run --memory-reservation=256m nginx

# Limite OOM (Out of Memory) kill
podman run --oom-kill-disable nginx  # ⚠️ Dangereux
```

### Limites CPU

```bash
# Limiter à 1.5 CPUs
podman run --cpus=1.5 nginx

# CPU shares (poids relatif)
podman run --cpu-shares=512 nginx

# Limiter à des CPUs spécifiques
podman run --cpuset-cpus=0,1 nginx

# Quota CPU (100000 = 100% d'un CPU)
podman run --cpu-quota=50000 --cpu-period=100000 nginx
```

### Limites I/O

```bash
# Limiter la bande passante I/O (en bytes/sec)
podman run --device-read-bps=/dev/sda:10mb nginx
podman run --device-write-bps=/dev/sda:10mb nginx

# Limiter les IOPS
podman run --device-read-iops=/dev/sda:100 nginx
podman run --device-write-iops=/dev/sda:100 nginx
```

### Limites réseau

```bash
# Via tc (traffic control) dans le conteneur
podman run --cap-add=NET_ADMIN nginx \
  sh -c "tc qdisc add dev eth0 root tbf rate 1mbit burst 32kbit latency 400ms"
```

### Limites de processus

```bash
# Limiter le nombre de PIDs (processus)
podman run --pids-limit=100 nginx

# Limiter les file descriptors
podman run --ulimit nofile=1024:2048 nginx

# Limiter les processus utilisateur
podman run --ulimit nproc=50 nginx
```

### Exemple complet avec limites

```bash
podman run -d \
  --name secure-app \
  --memory=512m \
  --memory-swap=1g \
  --cpus=1.0 \
  --pids-limit=100 \
  --ulimit nofile=1024:2048 \
  --ulimit nproc=50 \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --read-only \
  --security-opt=no-new-privileges \
  myapp:latest
```

---

## Options de sécurité avancées

### --read-only

Système de fichiers en lecture seule :

```bash
# Conteneur complètement read-only
podman run --read-only nginx

# Avec tmpfs pour /tmp
podman run --read-only --tmpfs /tmp nginx

# Avec volume pour les logs
podman run --read-only -v logs:/var/log:Z nginx
```

### --no-new-privileges

Empêche l'escalade de privilèges :

```bash
podman run --security-opt=no-new-privileges nginx
```

**Empêche :**
- Exécution de binaires setuid/setgid
- Gain de capabilities via execve()
- Changements de namespace privilégiés

### Seccomp profiles

Seccomp (Secure Computing Mode) filtre les appels système :

```bash
# Profil par défaut
podman run nginx  # Seccomp activé par défaut

# Désactiver seccomp (déconseillé)
podman run --security-opt seccomp=unconfined nginx

# Profil personnalisé
podman run --security-opt seccomp=/path/to/profile.json nginx
```

**Exemple de profil Seccomp :**

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": ["read", "write", "open", "close", "stat"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

---

## Bonnes pratiques - Checklist de sécurité

### Image

- [ ] Utiliser des images officielles et vérifiées
- [ ] Préférer les tags spécifiques (`:1.21.3`) plutôt que `:latest`
- [ ] Utiliser des images minimales (alpine, distroless, scratch)
- [ ] Scanner régulièrement avec Trivy ou équivalent
- [ ] Multi-stage builds pour exclure les outils de build
- [ ] Utilisateur non-root dans le Dockerfile (`USER`)
- [ ] Pas de secrets dans l'image

### Runtime

- [ ] Mode rootless par défaut
- [ ] Limites de ressources (memory, CPU, PIDs)
- [ ] `--cap-drop=ALL` puis ajouter uniquement ce qui est nécessaire
- [ ] `--read-only` avec tmpfs/volumes pour les écritures
- [ ] `--security-opt=no-new-privileges`
- [ ] Volumes avec `:Z` pour SELinux
- [ ] Pas de `--privileged`
- [ ] Pas de montage de sockets Docker/Podman sensibles

### Réseau

- [ ] Exposer uniquement les ports nécessaires
- [ ] Utiliser des réseaux personnalisés pour l'isolation
- [ ] Pas de `--net=host` sauf cas justifié

### Secrets

- [ ] Secrets via variables d'environnement runtime ou podman secrets
- [ ] Pas de secrets dans les images ou le code source
- [ ] Permissions strictes sur les fichiers de secrets
- [ ] Rotation régulière des secrets

### Maintenance

- [ ] Mettre à jour régulièrement Podman
- [ ] Mettre à jour les images de base
- [ ] Supprimer les images et conteneurs inutilisés
- [ ] Monitorer les logs pour détecter les anomalies
- [ ] Audits de sécurité réguliers

---

## Validation

Vous avez réussi si vous pouvez :

- Exécuter Podman en mode rootless
- Comprendre et configurer le mapping des user namespaces
- Retirer et ajouter des capabilities avec `--cap-drop` et `--cap-add`
- Configurer SELinux pour les volumes avec `:Z` et `:z`
- Scanner des images avec Trivy pour détecter les vulnérabilités
- Créer des Dockerfiles sécurisés avec utilisateurs non-root
- Gérer des secrets avec podman secrets ou volumes
- Appliquer des limites de ressources (mémoire, CPU, PIDs)
- Utiliser les options de sécurité avancées (`--read-only`, `--no-new-privileges`)
- Identifier et corriger les mauvaises pratiques de sécurité

---

## Résolution de problèmes

### Erreur : Permission denied sur un volume

```bash
# Problème : SELinux bloque l'accès
# Solution : Ajouter :Z
podman run -v ./data:/data:Z nginx

# Vérifier le contexte SELinux
ls -Z ./data
```

---

### Erreur : Cannot bind to port 80

```bash
# Problème : Ports < 1024 nécessitent des privilèges en rootless
# Solution 1 : Utiliser un port >= 1024
podman run -p 8080:80 nginx

# Solution 2 : Configurer net.ipv4.ip_unprivileged_port_start
sudo sysctl net.ipv4.ip_unprivileged_port_start=80
```

---

### Conteneur killed par OOM

```bash
# Problème : Conteneur utilise trop de mémoire
# Solution : Augmenter la limite ou optimiser l'application
podman run --memory=1g myapp

# Voir les statistiques mémoire
podman stats myapp
```

---

### Scanner Trivy échoue

```bash
# Problème : Base de données Trivy obsolète
# Solution : Mettre à jour la DB
trivy image --download-db-only

# Forcer le téléchargement
trivy image --reset nginx
```

---

### User namespace mapping ne fonctionne pas

```bash
# Vérifier /etc/subuid et /etc/subgid
grep $USER /etc/subuid
grep $USER /etc/subgid

# Si absent, ajouter (nécessite root)
sudo usermod --add-subuids 100000-165535 $USER
sudo usermod --add-subgids 100000-165535 $USER

# Redémarrer la session utilisateur
podman system migrate
```

---

### Capabilities insuffisantes

```bash
# Problème : Opération échoue par manque de capability
# Solution : Identifier la capability nécessaire
# Chercher dans les logs : "Operation not permitted"

# Ajouter la capability manquante
podman run --cap-add=NET_ADMIN myapp

# Lister les capabilities d'un conteneur en cours
podman inspect CONTAINER | grep -i cap
```

---

## Scripts de sécurité

### Audit de sécurité automatique

```bash
#!/bin/bash
# security-audit.sh

echo "=== Audit de sécurité Podman ==="
echo ""

# 1. Vérifier le mode
echo "📋 Mode d'exécution :"
podman info --format '{{.Host.Security.Rootless}}' | \
    sed 's/true/✓ Rootless activé/;s/false/✗ Mode root détecté/'

# 2. Lister les conteneurs avec privilèges élevés
echo ""
echo "🔍 Conteneurs potentiellement à risque :"
podman ps --format "{{.ID}}\t{{.Names}}" | while read id name; do
    privileged=$(podman inspect $id --format '{{.HostConfig.Privileged}}')
    caps=$(podman inspect $id --format '{{.HostConfig.CapAdd}}')

    if [ "$privileged" = "true" ]; then
        echo "⚠️  $name : Mode privileged activé"
    fi

    if [[ "$caps" == *"SYS_ADMIN"* ]]; then
        echo "⚠️  $name : CAP_SYS_ADMIN accordée"
    fi
done

# 3. Scanner les images
echo ""
echo "🔬 Scan des vulnérabilités :"
podman images --format "{{.Repository}}:{{.Tag}}" | \
    grep -v "<none>" | \
    while read image; do
        critical=$(trivy image --severity CRITICAL --quiet $image 2>/dev/null | grep -c "CRITICAL")
        if [ "$critical" -gt 0 ]; then
            echo "🔴 $image : $critical vulnérabilités CRITICAL"
        fi
    done

echo ""
echo "Audit terminé."
```

---

## Suite

Passez au [TP5B - AWS](../TP5B-aws/) pour apprendre à déployer vos conteneurs Podman sur AWS avec Terraform.
