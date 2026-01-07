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

# Comparer les images durcies
./scripts/compare-hardened-images.sh

# Tester les capabilities
./scripts/test-capabilities.sh

# Construire une image sécurisée standard
cd exemples
podman build -t secure-app -f Dockerfile-secure .

# Utiliser des images durcies (DHI - Docker Hardened Images)
podman login dhi.io  # Authentification avec Docker ID
podman pull dhi.io/python:3.13
podman run -d -p 5000:5000 dhi.io/python:3.13

# Construire des images durcies personnalisées
podman build -t myapp:distroless -f Dockerfile-distroless .
podman build -t myapp:chainguard -f Dockerfile-chainguard .
podman build -t myapp:ubi -f Dockerfile-ubi-micro .
podman build -t myapp:alpine -f Dockerfile-alpine-hardened .
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

## Images durcies (Hardened Images)

### Qu'est-ce qu'une DHI (Docker Hardened Image) ?

**DHI (Docker Hardened Image)** est le terme générique pour désigner une image de conteneur spécialement conçue et configurée pour offrir un niveau de sécurité maximal. Ces images sont également appelées **images durcies** ou **hardened images**.

Une **image durcie (hardened image)** est une image de conteneur spécialement conçue et configurée pour offrir un niveau de sécurité maximal :

**Caractéristiques principales :**
- 🛡️ **Sans CVE connus** : Patchée contre les vulnérabilités connues
- 📦 **Minimale** : Surface d'attaque réduite (pas de shell, packages minimaux)
- 🔒 **Configurations sécurisées** : Permissions strictes, utilisateur non-root
- 📝 **SBOM (Software Bill of Materials)** : Liste complète des composants
- ✅ **Signatures vérifiables** : Garantie d'authenticité
- 🔄 **Mises à jour rapides** : Patchs de sécurité en < 24h

### Pourquoi utiliser des images durcies ?

**Avantages :**
- ✅ Conformité réglementaire (PCI-DSS, HIPAA, SOC 2)
- ✅ Réduction des vulnérabilités de 60-90%
- ✅ Attaque surface minimale
- ✅ Moins de false positives dans les scans
- ✅ Approbation plus rapide des audits de sécurité
- ✅ Mises à jour de sécurité automatisées

**Cas d'usage :**
- Applications critiques (finance, santé, gouvernement)
- Environnements de production réglementés
- Infrastructure cloud sécurisée
- Chaînes CI/CD avec exigences de sécurité strictes

---

### Options gratuites

#### 1. Docker Hardened Images - dhi.io (⭐⭐⭐ Hautement Recommandé - Gratuit et Open Source)

**Description :** Images de conteneurs officielles durcies par Docker, maintenant **gratuites et open source** (Apache 2.0) depuis décembre 2025.

**Avantages :**
- ✅ **Zéro CVE connus** à la publication
- ✅ **100% gratuit et open source** (Apache 2.0)
- ✅ **SBOM complet** (Software Bill of Materials)
- ✅ **Signatures vérifiables** avec provenance supply chain
- ✅ **Mises à jour régulières** par Docker
- ✅ **Production-ready** avec configurations durcies
- ✅ **Pas de restrictions d'usage** ni de vendor lock-in
- ✅ Compatible avec Podman et tous les runtimes OCI

**Registre :** `dhi.io`

**Images disponibles :**
- `dhi.io/python` - Python (3.9, 3.10, 3.11, 3.12, 3.13)
- `dhi.io/node` - Node.js
- `dhi.io/postgres` - PostgreSQL
- `dhi.io/nginx` - Nginx
- `dhi.io/mongodb` - MongoDB
- `dhi.io/redis` - Redis
- `dhi.io/golang` - Go
- Et bien d'autres dans le [catalogue officiel](https://github.com/docker-hardened-images/catalog)

**Authentification :**

```bash
# Se connecter avec vos identifiants Docker ID (même que Docker Hub)
podman login dhi.io
# Username: votre_docker_id
# Password: votre_mot_de_passe
```

**Exemple d'utilisation simple :**

```bash
# Authentification
podman login dhi.io

# Pull d'une image durcie
podman pull dhi.io/python:3.13

# Lancer un conteneur
podman run -d -p 5000:5000 --name app-dhi dhi.io/python:3.13
```

**Exemple Dockerfile :**

```dockerfile
# Multi-stage build avec DHI
FROM dhi.io/python:3.13 AS builder

WORKDIR /app

# Installer les dépendances
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/dependencies -r requirements.txt

# Image finale
FROM dhi.io/python:3.13

WORKDIR /app

# Copier les dépendances
COPY --from=builder /app/dependencies /app/dependencies
COPY app.py .

# DHI utilise déjà un utilisateur non-root par défaut
ENV PYTHONPATH=/app/dependencies

CMD ["python", "app.py"]
```

**Scanner une image DHI :**

```bash
# Vérifier qu'il n'y a pas de CVE
trivy image --severity HIGH,CRITICAL dhi.io/python:3.13

# Résultat attendu : 0 vulnérabilités CRITICAL/HIGH
```

**Vérifier le SBOM :**

```bash
# Voir le Software Bill of Materials
podman image inspect dhi.io/python:3.13 --format '{{.Config.Labels}}'

# Ou utiliser syft
syft dhi.io/python:3.13
```

**Avantages par rapport aux alternatives :**
- ✅ **Maintenance officielle Docker** (plus de ressources que projets communautaires)
- ✅ **Gratuit sans restrictions** (contrairement à Chainguard Enterprise)
- ✅ **Large catalogue** d'images populaires
- ✅ **Migration facile** depuis les images Docker Hub classiques
- ✅ **Pas de changement de workflow** (même registre pattern)

**Upgrade vers DHI Enterprise (optionnel - payant) :**
- FIPS 140-2 compliance variants
- STIG compliance variants
- Customization capabilities
- SLA-backed support 24/7

**Site web :** https://www.docker.com/products/hardened-images/

---

#### 2. Google Distroless (⭐ Recommandé - Gratuit)

**Description :** Images minimales sans distribution Linux complète, créées par Google.

**Avantages :**
- ✅ Pas de shell, package manager, ou outils système
- ✅ Surface d'attaque minimale
- ✅ Images très légères
- ✅ Mises à jour régulières par Google
- ✅ 100% gratuit et open source

**Images disponibles :**
- `gcr.io/distroless/static` - Binaires statiques seulement
- `gcr.io/distroless/base` - glibc + openssl
- `gcr.io/distroless/python3` - Python 3
- `gcr.io/distroless/java17` - OpenJDK 17
- `gcr.io/distroless/nodejs` - Node.js
- `gcr.io/distroless/cc` - C/C++

**Exemple Dockerfile :**

```dockerfile
# Multi-stage avec Distroless
FROM golang:1.21 AS builder
WORKDIR /build
COPY . .
RUN CGO_ENABLED=0 go build -o app

# Image finale distroless
FROM gcr.io/distroless/static-debian12:nonroot

# Copier uniquement le binaire
COPY --from=builder /build/app /app

USER nonroot:nonroot

CMD ["/app"]
```

**Utilisation avec Python :**

```dockerfile
FROM python:3.13-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/dependencies -r requirements.txt

FROM gcr.io/distroless/python3-debian12:nonroot
WORKDIR /app

# Copier les dépendances et l'application
COPY --from=builder /app/dependencies /app
COPY app.py .

ENV PYTHONPATH=/app

USER nonroot:nonroot

CMD ["app.py"]
```

**Limitations :**
- ⚠️ Pas de shell → Difficile à déboguer
- ⚠️ Pas de package manager → Pas d'installation à runtime
- ⚠️ Nécessite multi-stage builds

**Debug d'une image Distroless :**
```bash
# Utiliser la variante :debug (temporaire uniquement)
FROM gcr.io/distroless/python3-debian12:debug

# Lancer un shell pour debug
podman run -it --entrypoint /busybox/sh myapp:debug
```

---

#### 3. Wolfi / Chainguard Images (⭐⭐ Recommandé - Gratuit)

**Description :** Distribution Linux ultra-minimale créée par Chainguard, avec mises à jour de sécurité en < 24h.

**Avantages :**
- ✅ **Zéro CVE connus** à la publication
- ✅ Patchs de sécurité ultra-rapides (< 24h)
- ✅ SBOM natif (Software Bill of Materials)
- ✅ Images signées avec Sigstore
- ✅ Compatible glibc (pas musl comme Alpine)
- ✅ Versions gratuites disponibles sur Docker Hub

**Images gratuites (cgr.dev) :**
- `cgr.dev/chainguard/python:latest` - Python
- `cgr.dev/chainguard/node:latest` - Node.js
- `cgr.dev/chainguard/go:latest` - Go
- `cgr.dev/chainguard/nginx:latest` - Nginx
- `cgr.dev/chainguard/postgres:latest` - PostgreSQL
- `cgr.dev/chainguard/redis:latest` - Redis

**Exemple Dockerfile :**

```dockerfile
FROM cgr.dev/chainguard/python:latest-dev AS builder

WORKDIR /app
COPY requirements.txt .

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

FROM cgr.dev/chainguard/python:latest

WORKDIR /app

# Copier les dépendances depuis le builder
COPY --from=builder /home/nonroot/.local /home/nonroot/.local
COPY app.py .

# Wolfi utilise l'utilisateur nonroot (UID 65532)
USER nonroot

ENV PATH=/home/nonroot/.local/bin:$PATH

CMD ["python", "app.py"]
```

**Vérifier les signatures :**

```bash
# Installer cosign
curl -O -L https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Vérifier la signature d'une image
cosign verify cgr.dev/chainguard/python:latest \
  --certificate-identity-regexp=https://github.com/chainguard-images \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**Comparaison Gratuit vs Payant :**

| Fonctionnalité | Gratuit (Public) | Entreprise (Payant) |
|----------------|------------------|---------------------|
| Images de base | ✅ Oui | ✅ Oui |
| Mises à jour | ✅ Best effort | ✅ Garanties SLA |
| Support | ⚠️ Communauté | ✅ Support 24/7 |
| Images privées | ❌ Non | ✅ Oui |
| FIPS compliance | ❌ Non | ✅ Oui |
| Conformité FedRAMP | ❌ Non | ✅ Oui |

---

#### 4. Alpine Linux Hardened

**Description :** Distribution Linux minimale avec profil de sécurité renforcé.

**Avantages :**
- ✅ Très légère (5 MB)
- ✅ Package manager (apk)
- ✅ Communauté active
- ✅ Largement utilisée

**Exemple Dockerfile :**

```dockerfile
FROM alpine:3.19

# Installer les dépendances minimales
RUN apk add --no-cache python3 py3-pip

# Créer utilisateur non-root
RUN adduser -D -u 1001 appuser

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

COPY app.py .

RUN chown -R appuser:appuser /app

USER appuser

CMD ["python3", "app.py"]
```

**Durcir Alpine :**

```dockerfile
FROM alpine:3.19

# 1. Mettre à jour tous les packages
RUN apk upgrade --no-cache

# 2. Supprimer les packages inutiles
RUN apk del --purge apk-tools

# 3. Supprimer les caches
RUN rm -rf /var/cache/apk/* /tmp/*

# 4. Utilisateur non-root avec UID élevé
RUN adduser -D -u 10001 -s /sbin/nologin appuser

USER appuser

CMD ["/app"]
```

**Limitations :**
- ⚠️ Utilise musl libc (incompatibilités possibles)
- ⚠️ Packages parfois obsolètes
- ⚠️ Peut contenir des CVE

---

#### 5. Red Hat Universal Base Images (UBI)

**Description :** Images de base de Red Hat, redistribuables gratuitement.

**Avantages :**
- ✅ Gratuites (pas besoin d'abonnement RHEL)
- ✅ Patchs de sécurité réguliers
- ✅ Compatibilité RHEL
- ✅ Support communautaire

**Images disponibles :**
- `registry.access.redhat.com/ubi9/ubi` - Complète
- `registry.access.redhat.com/ubi9/ubi-minimal` - Minimale
- `registry.access.redhat.com/ubi9/ubi-micro` - Ultra-minimale
- `registry.access.redhat.com/ubi9/python-311` - Python 3.11
- `registry.access.redhat.com/ubi9/nodejs-18` - Node.js 18

**Exemple Dockerfile :**

```dockerfile
FROM registry.access.redhat.com/ubi9/python-311

# Copier l'application
WORKDIR /app
COPY requirements.txt .

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# UBI utilise UID 1001 par défaut
USER 1001

CMD ["python", "app.py"]
```

**UBI Micro (ultra-minimale) :**

```dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

RUN microdnf install -y python3 python3-pip
COPY requirements.txt .
RUN pip3 install --target=/app/deps -r requirements.txt

# Image finale micro (pas de package manager)
FROM registry.access.redhat.com/ubi9/ubi-micro

COPY --from=builder /usr/bin/python3 /usr/bin/
COPY --from=builder /app/deps /app/deps
COPY app.py /app/

ENV PYTHONPATH=/app/deps

USER 1001

CMD ["/usr/bin/python3", "/app/app.py"]
```

---

#### 6. Iron Bank (DoD Hardened Containers)

**Description :** Dépôt d'images durcies du Département de la Défense américain (DoD).

**Avantages :**
- ✅ Standards de sécurité militaires (DISA STIG)
- ✅ Scans et audits rigoureux
- ✅ Certaines images publiques gratuites
- ✅ Conformité FedRAMP, NIST

**Accès :**
- Public : `registry1.dso.mil` (images limitées)
- Privé : Nécessite compte DoD CAC/PKI

**Exemple d'images publiques :**
- `registry1.dso.mil/ironbank/opensource/nginx/nginx:latest`
- `registry1.dso.mil/ironbank/opensource/postgres/postgresql:latest`

```bash
# Utiliser une image Iron Bank
podman pull registry1.dso.mil/ironbank/opensource/nginx/nginx:1.24

podman run -d -p 8080:8080 \
  registry1.dso.mil/ironbank/opensource/nginx/nginx:1.24
```

**Note :** Accès complet nécessite enregistrement sur https://registry1.dso.mil

---

### Options payantes

#### 1. Chainguard Images Enterprise (⭐ Recommandé)

**Prix :** Sur devis (environ $50-150/image/mois selon volume)

**Avantages supplémentaires vs gratuit :**
- ✅ **SLA de patching < 24h** (garanti contractuellement)
- ✅ **Support 24/7** avec ingénieurs sécurité
- ✅ **Images privées personnalisées**
- ✅ **FIPS 140-2 compliance**
- ✅ **FedRAMP Moderate authorized**
- ✅ **Dashboard de gouvernance** (CVE tracking, compliance)
- ✅ **Intégrations avancées** (Kubernetes admission controllers)
- ✅ **Attestations de build** (provenance SLSA)

**Cas d'usage :**
- Entreprises soumises à conformité stricte
- Services financiers, santé réglementée
- Contrats gouvernementaux (FedRAMP)

**Site web :** https://www.chainguard.dev/chainguard-images

---

#### 2. Red Hat UBI avec abonnement RHEL

**Prix :** Inclus avec abonnement Red Hat Enterprise Linux ($349-$1299/an)

**Avantages supplémentaires :**
- ✅ Support officiel Red Hat
- ✅ SLA de sécurité garantis
- ✅ Extended Lifecycle Support (ELS)
- ✅ Accès au support technique 24/7
- ✅ Conformité certifiée (ISO, FIPS)

**Cas d'usage :**
- Infrastructures déjà sur RHEL
- Nécessite support entreprise

---

#### 3. VMware Bitnami+

**Prix :** Sur devis (intégré à VMware Tanzu)

**Avantages :**
- ✅ Images maintenues et patchées par VMware
- ✅ Support commercial 24/7
- ✅ Intégration avec VMware Tanzu
- ✅ Scans de vulnérabilités automatiques

**Cas d'usage :**
- Entreprises utilisant VMware
- Besoin de support commercial

---

#### 4. Aqua Security DTA (Dynamic Threat Analysis)

**Prix :** Sur devis (plateforme complète)

**Description :** Plateforme de sécurité complète avec images durcies.

**Avantages :**
- ✅ Images durcies + plateforme de sécurité
- ✅ Runtime protection
- ✅ Compliance automatisée
- ✅ Threat intelligence intégrée

---

### Comparaison des options

| Solution | Coût | CVE | SBOM | Support | FIPS | Complexité |
|----------|------|-----|------|---------|------|------------|
| **dhi.io (Docker DHI)** | Gratuit | ✅ Excellent | ✅ | Docker/Communauté | ⚠️ Enterprise | Très faible |
| **Wolfi/Chainguard Public** | Gratuit | ✅ Excellent | ✅ | Communauté | ❌ | Faible |
| **Distroless** | Gratuit | ⚠️ Moyen | ✅ | Communauté | ❌ | Moyenne |
| **Alpine** | Gratuit | ⚠️ Moyen | ⚠️ | Communauté | ❌ | Faible |
| **UBI (gratuit)** | Gratuit | ✅ Bon | ✅ | Communauté | ⚠️ | Faible |
| **Iron Bank** | Gratuit* | ✅ Excellent | ✅ | Limité | ✅ | Moyenne |
| **Chainguard Enterprise** | $$$ | ✅ Excellent | ✅ | 24/7 | ✅ | Faible |
| **UBI + RHEL** | $$ | ✅ Excellent | ✅ | 24/7 | ✅ | Faible |

*Iron Bank : Gratuit pour images publiques, CAC requis pour accès complet

---

### Recommandations par contexte

**Développement / Projets personnels :**
- 🥇 **dhi.io (Docker DHI)** (zéro CVE, gratuit, simple)
- 🥈 Wolfi/Chainguard Public (zéro CVE, gratuit)
- 🥉 Distroless (minimaliste)

**Startup / PME :**
- 🥇 **dhi.io (Docker DHI)** (excellent rapport sécurité/coût/simplicité)
- 🥈 Wolfi/Chainguard Public (excellent rapport sécurité/coût)
- 🥉 UBI gratuit (stabilité Red Hat)

**Entreprise (sans contraintes réglementaires) :**
- 🥇 **dhi.io (Docker DHI)** (gratuit, maintenance officielle)
- 🥈 Wolfi/Chainguard Public
- 🥉 UBI + RHEL (si infrastructure Red Hat)

**Entreprise réglementée (finance, santé) :**
- 🥇 **Chainguard Enterprise** (FIPS, SLA, FedRAMP)
- 🥈 DHI Enterprise (FIPS, STIG, support SLA)
- 🥉 UBI + RHEL (support 24/7)
- 🏅 Iron Bank (si gouvernement US)

**Gouvernement / Défense (US) :**
- 🥇 **Iron Bank** (DISA STIG, FedRAMP High)
- 🥈 DHI Enterprise (FIPS, STIG compliance)
- 🥉 Chainguard Enterprise (FedRAMP Moderate)

**Infrastructure Kubernetes production :**
- 🥇 **dhi.io (Docker DHI)** (simple, gratuit, maintenance officielle)
- 🥈 Chainguard Enterprise (admission controllers)
- 🥉 Wolfi/Chainguard Public

---

### Scanner et comparer les images

**Script de comparaison :**

```bash
#!/bin/bash
# compare-images.sh - Compare les vulnérabilités de différentes images

echo "=== Comparaison d'images durcies ==="
echo ""

IMAGES=(
  "python:3.13-slim"
  "python:3.13-alpine"
  "dhi.io/python:3.13"
  "cgr.dev/chainguard/python:latest"
  "gcr.io/distroless/python3-debian12"
  "registry.access.redhat.com/ubi9/python-311"
)

for image in "${IMAGES[@]}"; do
  echo "📦 Image: $image"

  # Pull l'image
  podman pull $image 2>/dev/null

  # Scanner avec Trivy
  critical=$(trivy image --severity CRITICAL --quiet $image 2>/dev/null | grep -c "CRITICAL" || echo "0")
  high=$(trivy image --severity HIGH --quiet $image 2>/dev/null | grep -c "HIGH" || echo "0")

  # Taille de l'image
  size=$(podman images $image --format "{{.Size}}")

  echo "   🔴 CRITICAL: $critical"
  echo "   🟠 HIGH: $high"
  echo "   💾 Size: $size"
  echo ""
done

echo "Recommandation: Utilisez l'image avec le moins de vulnérabilités"
```

**Exécution :**

```bash
chmod +x compare-images.sh
./compare-images.sh
```

---

### Vérification et validation

**Checklist pour valider une image durcie :**

- [ ] Scan Trivy sans vulnérabilités CRITICAL/HIGH
- [ ] Utilisateur non-root configuré
- [ ] Pas de shell dans l'image finale (distroless/micro)
- [ ] SBOM disponible et vérifiable
- [ ] Signature d'image vérifiée (cosign)
- [ ] Image multi-stage (build séparé du runtime)
- [ ] Pas de secrets dans les layers
- [ ] Permissions fichiers restrictives
- [ ] Read-only filesystem compatible
- [ ] Documentation des exceptions de sécurité

**Commandes de validation :**

```bash
# 1. Scanner l'image
trivy image --severity HIGH,CRITICAL myapp:latest

# 2. Vérifier l'utilisateur
podman run --rm myapp:latest id

# 3. Vérifier les packages installés
podman run --rm myapp:latest sh -c "apk list" 2>/dev/null || echo "Pas de package manager (OK)"

# 4. Tester le read-only filesystem
podman run --read-only --tmpfs /tmp myapp:latest

# 5. Vérifier les capabilities
podman run --rm myapp:latest capsh --print 2>/dev/null || echo "Pas de capsh (OK)"
```

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

**Solution propriétaire (BSL 1.1 depuis v1.14)** - Puissante mais licence restrictive

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

##### B. OpenBao (⭐ Recommandé - 100% Open Source)

**Alternative open-source à Vault** - Fork maintenu par la Linux Foundation (MPL 2.0)

OpenBao est un fork communautaire de Vault créé après le changement de licence de HashiCorp. **Compatible API** avec Vault, migration facile.

**Installation :**

```bash
# Via binaire (Linux)
curl -fsSL https://github.com/openbao/openbao/releases/download/v2.0.0/bao_2.0.0_linux_amd64.zip -o bao.zip
unzip bao.zip
sudo mv bao /usr/local/bin/
chmod +x /usr/local/bin/bao

# Vérifier l'installation
bao version
```

**Lancement rapide avec Podman (mode dev) :**

```bash
# Lancer OpenBao en mode développement
podman run -d \
  --name openbao-dev \
  -p 8200:8200 \
  -e BAO_DEV_ROOT_TOKEN_ID=dev-token-123 \
  --cap-add IPC_LOCK \
  quay.io/openbao/openbao:latest server -dev

# Configurer le client
export BAO_ADDR='http://localhost:8200'
export BAO_TOKEN='dev-token-123'

# Vérifier le statut
bao status
```

**Utilisation des secrets :**

```bash
# Activer le moteur KV v2
bao secrets enable -version=2 kv

# Créer des secrets
bao kv put kv/myapp/db password="super_secure_password" username="dbuser"
bao kv put kv/myapp/api key="api_secret_xyz_789"

# Lire un secret
bao kv get kv/myapp/db

# Récupérer une valeur spécifique
DB_PASSWORD=$(bao kv get -field=password kv/myapp/db)

# Injecter dans Podman Secrets
echo "$DB_PASSWORD" | podman secret create db_password -
podman run --secret db_password myapp
```

**Application avec OpenBao (Python) :**

```python
# Python avec hvac (compatible OpenBao)
import hvac
import os

# OpenBao utilise la même API que Vault
client = hvac.Client(
    url=os.getenv('BAO_ADDR', 'http://localhost:8200'),
    token=os.getenv('BAO_TOKEN')
)

# Vérifier que le client est authentifié
if not client.is_authenticated():
    raise Exception("Authentication failed")

# Récupérer un secret (KV v2)
secret_response = client.secrets.kv.v2.read_secret_version(
    path='myapp/db',
    mount_point='kv'
)

db_password = secret_response['data']['data']['password']
db_username = secret_response['data']['data']['username']

print(f"Connecté à la DB avec l'utilisateur: {db_username}")
```

**Déploiement production avec Podman Compose :**

Voir `exemples/openbao-compose.yaml` pour un exemple complet.

**Rotation automatique des secrets :**

```bash
# Générer une nouvelle version du secret
NEW_PASSWORD=$(openssl rand -base64 32)
bao kv put kv/myapp/db password="$NEW_PASSWORD" username="dbuser"

# OpenBao garde l'historique (versioning)
bao kv get -version=1 kv/myapp/db  # Ancienne version
bao kv get -version=2 kv/myapp/db  # Nouvelle version

# Mettre à jour le secret Podman
echo "$NEW_PASSWORD" | podman secret create db_password_v2 -

# Redéployer avec le nouveau secret
podman run --secret db_password_v2,target=/run/secrets/db_password myapp
```

**Politiques d'accès (policies) :**

```bash
# Créer une politique pour l'application
cat > myapp-policy.hcl <<EOF
path "kv/data/myapp/*" {
  capabilities = ["read"]
}
EOF

bao policy write myapp-readonly myapp-policy.hcl

# Créer un token avec cette politique
bao token create -policy=myapp-readonly

# L'application ne peut que lire, pas modifier
```

**Avantages d'OpenBao :**
- ✅ **100% Open Source** (MPL 2.0) - Pas de restrictions de licence
- ✅ **Compatible API Vault** - Migration facile
- ✅ **Gouvernance communautaire** (Linux Foundation)
- ✅ **Gratuit** pour tous les cas d'usage
- ✅ Chiffrement, rotation, audit trail complet
- ✅ Haute disponibilité (clustering)
- ✅ Intégration cloud (AWS, Azure, GCP)
- ✅ Support multi-backend (Consul, PostgreSQL, etc.)

**Comparaison Vault vs OpenBao :**

| Critère | HashiCorp Vault | OpenBao |
|---------|-----------------|---------|
| Licence | BSL 1.1 (restrictive) | MPL 2.0 (permissive) |
| Coût | Gratuit / Entreprise payant | Gratuit |
| Gouvernance | HashiCorp | Linux Foundation |
| Compatibilité API | Originale | Compatible Vault |
| Développement | HashiCorp seul | Communauté |
| Support commercial | ✅ Officiel | ⚠️ Tiers uniquement |

##### C. AWS Secrets Manager

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

##### D. Azure Key Vault

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

##### E. Google Cloud Secret Manager

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
- ✅ Podman Secrets (simple et efficace)
- ✅ OpenBao en mode dev (pour tester la prod)
- ⚠️ Volumes montés (acceptable)

**Tests / Staging :**
- ✅ Podman Secrets
- ✅ **OpenBao** (open-source, recommandé)
- ✅ Vault (si licence acceptable)

**Production :**
- ✅ **OpenBao** (MPL 2.0 - 100% open source, recommandé)
- ✅ Vault / AWS / Azure / GCP
- ✅ Podman Secrets (acceptable pour petites applications)

**Production avec contraintes de licence :**
- ✅ **OpenBao** (MPL 2.0 - permissive)
- ⚠️ Vault (BSL 1.1 - restrictions d'usage commercial)

**Applications critiques (banque, santé) :**
- ✅ UNIQUEMENT gestionnaires externes (OpenBao, Vault, Cloud)
- ✅ Avec HSM (Hardware Security Module)
- ✅ Rotation automatique obligatoire
- ✅ Audit trail complet
- ✅ Haute disponibilité (clustering)

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
