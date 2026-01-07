# Exemples d'images durcies (Hardened Images)

Ce répertoire contient des exemples pratiques de Dockerfiles utilisant différentes images durcies pour maximiser la sécurité.

## Fichiers disponibles

### Dockerfiles d'images durcies

1. **`Dockerfile-dhi`** - Docker Hardened Images / dhi.io (⭐ Recommandé - Gratuit)
   - Zéro CVE connus, SBOM complet, signatures vérifiables
   - Maintenance officielle Docker
   - Open source (Apache 2.0)
   - Idéal pour : Tous types d'applications (meilleur choix général)

2. **`Dockerfile-distroless`** - Google Distroless (Gratuit)
   - Image minimale sans shell ni package manager
   - Surface d'attaque réduite au maximum
   - Idéal pour : Applications Python en production

3. **`Dockerfile-chainguard`** - Chainguard/Wolfi (Gratuit)
   - Zéro CVE connus à la publication
   - Mises à jour ultra-rapides (< 24h)
   - SBOM et signatures Sigstore
   - Idéal pour : Projets nécessitant conformité stricte

4. **`Dockerfile-ubi-micro`** - Red Hat UBI Micro (Gratuit)
   - Image ultra-minimale de Red Hat
   - Patchs de sécurité réguliers
   - Compatible RHEL
   - Idéal pour : Infrastructures Red Hat

5. **`Dockerfile-alpine-hardened`** - Alpine durcie
   - Image très légère (~5MB)
   - Configurations de sécurité renforcées
   - Idéal pour : Contraintes de taille

### Application d'exemple

- **`app.py`** - Application Flask simple pour tester les images
- **`requirements.txt`** - Dépendances Python

## Construction et test des images

### 0. Docker Hardened Images (dhi.io) ⭐ Recommandé

```bash
# Prérequis : Authentification au registre dhi.io
podman login dhi.io
# Username: votre_docker_id (même que Docker Hub)
# Password: votre_mot_de_passe

# Construire
podman build -t myapp:dhi -f Dockerfile-dhi .

# Tester
podman run -d -p 5000:5000 --name app-dhi myapp:dhi

# Vérifier
curl http://localhost:5000/
curl http://localhost:5000/health

# Nettoyer
podman stop app-dhi
podman rm app-dhi
```

**Caractéristiques :**
- ✅ **Zéro CVE connus** à la publication
- ✅ **SBOM complet** (Software Bill of Materials)
- ✅ **Signatures vérifiables** avec provenance
- ✅ **Utilisateur non-root** préconfiguré
- ✅ **Gratuit et open source** (Apache 2.0)
- ✅ **Maintenance officielle Docker**

**Scanner l'image :**

```bash
# Vérifier les vulnérabilités (devrait être 0)
trivy image --severity HIGH,CRITICAL myapp:dhi

# Voir le SBOM
syft myapp:dhi
```

**Lancer avec sécurité maximale :**

```bash
podman run -d \
  --name app-dhi-secure \
  -p 5000:5000 \
  --read-only \
  --tmpfs /tmp \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  --memory=512m \
  --cpus=1.0 \
  --pids-limit=100 \
  myapp:dhi
```

**Pourquoi choisir dhi.io ?**
- 🥇 **Maintenance officielle** : Soutenu par Docker Inc.
- 🥇 **Simple** : Même workflow que Docker Hub
- 🥇 **Gratuit** : Pas de frais, pas de restrictions
- 🥇 **Sécurité** : Zéro CVE, SBOM, signatures
- 🥇 **Production-ready** : Configurations durcies par défaut

---

### 1. Distroless

```bash
# Construire
podman build -t myapp:distroless -f Dockerfile-distroless .

# Tester
podman run -d -p 5000:5000 --name app-distroless myapp:distroless

# Vérifier
curl http://localhost:5000/
curl http://localhost:5000/health

# Nettoyer
podman stop app-distroless
podman rm app-distroless
```

**Caractéristiques :**
- ✅ Pas de shell (impossible de faire `podman exec`)
- ✅ Utilisateur non-root (UID 65532)
- ✅ Multi-stage build
- ✅ Image finale très petite

**Déboguer une image Distroless :**

```bash
# Option 1 : Utiliser la variante :debug
podman run -it --entrypoint /busybox/sh myapp:distroless-debug

# Option 2 : Utiliser ephemeral debug container
podman debug myapp:distroless
```

---

### 2. Chainguard (Wolfi)

```bash
# Construire
podman build -t myapp:chainguard -f Dockerfile-chainguard .

# Tester
podman run -d -p 5001:5000 --name app-chainguard myapp:chainguard

# Vérifier
curl http://localhost:5001/
curl http://localhost:5001/health

# Vérifier la signature (nécessite cosign)
cosign verify cgr.dev/chainguard/python:latest \
  --certificate-identity-regexp=https://github.com/chainguard-images \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com

# Nettoyer
podman stop app-chainguard
podman rm app-chainguard
```

**Caractéristiques :**
- ✅ Zéro CVE connus
- ✅ SBOM natif
- ✅ Signatures vérifiables (Sigstore)
- ✅ Mises à jour ultra-rapides

**Scanner les vulnérabilités :**

```bash
# Avant construction
trivy image --severity HIGH,CRITICAL cgr.dev/chainguard/python:latest

# Après construction
trivy image --severity HIGH,CRITICAL myapp:chainguard
```

---

### 3. Red Hat UBI Micro

```bash
# Construire
podman build -t myapp:ubi -f Dockerfile-ubi-micro .

# Tester
podman run -d -p 5002:5000 --name app-ubi myapp:ubi

# Vérifier
curl http://localhost:5002/
curl http://localhost:5002/health

# Nettoyer
podman stop app-ubi
podman rm app-ubi
```

**Caractéristiques :**
- ✅ Pas de package manager dans l'image finale
- ✅ Patchs Red Hat réguliers
- ✅ Compatible RHEL
- ✅ Gratuit (pas besoin d'abonnement)

**Options de sécurité avancées :**

```bash
# Lancer avec toutes les options de sécurité
podman run -d \
  --name app-ubi-secure \
  -p 5002:5000 \
  --read-only \
  --tmpfs /tmp \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  --memory=512m \
  --cpus=0.5 \
  myapp:ubi
```

---

### 4. Alpine durcie

```bash
# Construire
podman build -t myapp:alpine -f Dockerfile-alpine-hardened .

# Tester
podman run -d -p 5003:5000 --name app-alpine myapp:alpine

# Vérifier
curl http://localhost:5003/
curl http://localhost:5003/health

# Nettoyer
podman stop app-alpine
podman rm app-alpine
```

**Caractéristiques :**
- ✅ Très légère (~30-40MB pour Python)
- ✅ Utilisateur non-root avec UID élevé (10001)
- ✅ Shell désactivé (/sbin/nologin)
- ✅ Permissions fichiers strictes

**Durcir davantage :**

```bash
# Lancer en read-only avec limitations
podman run -d \
  --name app-alpine-hardened \
  -p 5003:5000 \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,nodev \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --security-opt=no-new-privileges \
  --memory=256m \
  --pids-limit=50 \
  myapp:alpine
```

---

## Comparaison des images

### Tableau comparatif

| Image | Taille* | CVE (CRITICAL) | CVE (HIGH) | Shell | Package Manager | Complexité |
|-------|---------|----------------|------------|-------|-----------------|------------|
| python:3.13 | ~1 GB | ⚠️ Élevé | ⚠️ Élevé | ✅ Oui | ✅ Oui | Faible |
| python:3.13-slim | ~150 MB | ⚠️ Moyen | ⚠️ Moyen | ✅ Oui | ✅ Oui | Faible |
| python:3.13-alpine | ~50 MB | ⚠️ Faible | ⚠️ Faible | ✅ Oui | ✅ Oui | Faible |
| **dhi.io/python** | ~60 MB | ✅ **Zéro** | ✅ **Zéro** | ⚠️ Minimal | ⚠️ Minimal | **Très faible** |
| **Distroless** | ~60 MB | ✅ Très faible | ✅ Très faible | ❌ Non | ❌ Non | Moyenne |
| **Chainguard** | ~40 MB | ✅ **Zéro** | ✅ **Zéro** | ⚠️ Minimal | ⚠️ Minimal | Moyenne |
| **UBI Micro** | ~80 MB | ✅ Très faible | ✅ Faible | ❌ Non | ❌ Non | Élevée |
| **Alpine durcie** | ~40 MB | ⚠️ Faible | ⚠️ Faible | ❌ Désactivé | ✅ Oui | Faible |

*Tailles approximatives avec application Flask

### Script de comparaison automatique

Utilisez le script fourni pour comparer toutes les images :

```bash
cd ../scripts
./compare-hardened-images.sh
```

Ce script va :
1. Télécharger toutes les images de base
2. Scanner avec Trivy pour détecter les CVE
3. Comparer les tailles
4. Afficher un tableau de comparaison
5. Donner des recommandations par contexte

---

## Tests de sécurité

### Scanner les images construites

```bash
# Scanner une image spécifique
trivy image --severity HIGH,CRITICAL myapp:distroless
trivy image --severity HIGH,CRITICAL myapp:chainguard
trivy image --severity HIGH,CRITICAL myapp:ubi
trivy image --severity HIGH,CRITICAL myapp:alpine

# Format JSON pour automatisation
trivy image --format json --output results.json myapp:distroless

# Ignorer les CVE non corrigées
trivy image --ignore-unfixed myapp:distroless
```

### Vérifier l'utilisateur non-root

```bash
# Vérifier l'UID de chaque image
podman run --rm myapp:distroless python -c "import os; print(f'UID: {os.getuid()}')"
podman run --rm myapp:chainguard python -c "import os; print(f'UID: {os.getuid()}')"
podman run --rm myapp:ubi python -c "import os; print(f'UID: {os.getuid()}')"
podman run --rm myapp:alpine python3 -c "import os; print(f'UID: {os.getuid()}')"
```

**Résultats attendus :**
- Distroless : UID 65532 (nonroot)
- Chainguard : UID 65532 (nonroot)
- UBI Micro : UID 1001
- Alpine : UID 10001 (appuser)

### Tester le système de fichiers read-only

```bash
# Toutes ces commandes devraient fonctionner
podman run --read-only --tmpfs /tmp --rm myapp:distroless
podman run --read-only --tmpfs /tmp --rm myapp:chainguard
podman run --read-only --tmpfs /tmp --rm myapp:ubi
podman run --read-only --tmpfs /tmp --rm myapp:alpine
```

### Tester les capabilities

```bash
# Vérifier qu'aucune capability dangereuse n'est présente
podman run --rm --cap-drop=ALL myapp:distroless || echo "Pas de shell - OK"
podman run --rm --cap-drop=ALL myapp:chainguard
podman run --rm --cap-drop=ALL myapp:ubi
podman run --rm --cap-drop=ALL myapp:alpine
```

---

## Recommandations par cas d'usage

### 🏠 Développement / Projets personnels

**Recommandation : dhi.io (Docker Hardened Images) ⭐**

```bash
podman login dhi.io
podman build -t myapp -f Dockerfile-dhi .
```

**Alternatives :**
- Chainguard Public
- Distroless

**Pourquoi dhi.io :**
- ✅ Gratuit et open source (Apache 2.0)
- ✅ Zéro CVE connus
- ✅ Simple (même workflow que Docker Hub)
- ✅ Maintenance officielle Docker

---

### 🏢 Startup / PME

**Recommandation : dhi.io (Docker Hardened Images) ⭐**

```bash
podman login dhi.io
podman build -t myapp -f Dockerfile-dhi .
```

**Alternatives :**
- Chainguard Public

**Pourquoi :**
- ✅ Excellent rapport sécurité/coût/simplicité (gratuit)
- ✅ Mises à jour régulières
- ✅ SBOM et signatures pour conformité
- ✅ Pas de vendor lock-in

---

### 🏭 Entreprise (production)

**Recommandation : dhi.io ou Chainguard Public**

```bash
# Option 1 : dhi.io (recommandé)
podman login dhi.io
podman build -t myapp -f Dockerfile-dhi .

# Option 2 : Chainguard
podman build -t myapp -f Dockerfile-chainguard .

# Option 3 : UBI si infrastructure Red Hat existante
podman build -t myapp -f Dockerfile-ubi-micro .
```

**Pourquoi :**
- ✅ Zéro CVE
- ✅ Patchs réguliers
- ✅ Support communautaire actif
- ✅ Gratuit

**Upgrade vers version payante si :**
- Besoin de SLA contractuels (DHI Enterprise / Chainguard Enterprise)
- Conformité FIPS requise
- Support 24/7 nécessaire

---

### 🏦 Entreprise réglementée (finance, santé)

**Recommandation : DHI Enterprise ou Chainguard Enterprise (payants)**

```bash
# Option 1 : DHI Enterprise
# Contact : https://www.docker.com/products/hardened-images/

# Option 2 : Chainguard Enterprise
# Contact : https://www.chainguard.dev/chainguard-images

# Option 3 : Red Hat UBI avec abonnement RHEL
podman build -t myapp -f Dockerfile-ubi-micro .
```

**Pourquoi :**
- ✅ SLA de patching < 24h garanti
- ✅ FIPS 140-2 / STIG compliance
- ✅ Support 24/7
- ✅ Conformité certifiée (PCI-DSS, HIPAA)

---

### 🎖️ Gouvernement / Défense (US)

**Recommandation : Iron Bank ou DHI Enterprise**

```bash
# Option 1 : Iron Bank (DISA STIG, FedRAMP High)
# Accès via registry1.dso.mil (nécessite compte)
podman pull registry1.dso.mil/ironbank/opensource/python/python39

# Option 2 : DHI Enterprise (FIPS, STIG compliance)
# Contact : https://www.docker.com/products/hardened-images/
```

**Pourquoi :**
- ✅ Standards DISA STIG
- ✅ FedRAMP High compliance
- ✅ Audits militaires rigoureux

---

## Bonnes pratiques

### Checklist de validation

Avant de déployer en production, vérifiez :

- [ ] **Scan Trivy** : 0 vulnérabilités CRITICAL/HIGH
- [ ] **Utilisateur non-root** : UID > 1000
- [ ] **Multi-stage build** : Build séparé du runtime
- [ ] **Pas de shell** : Impossible de faire `podman exec bash`
- [ ] **Pas de secrets** : Aucun secret dans l'image
- [ ] **Read-only compatible** : Fonctionne avec `--read-only`
- [ ] **Capabilities minimales** : Fonctionne avec `--cap-drop=ALL`
- [ ] **Limites de ressources** : `--memory` et `--cpus` configurées
- [ ] **SELinux/AppArmor** : Labels de sécurité configurés
- [ ] **SBOM disponible** : Pour audit et conformité

### Script de validation automatique

```bash
#!/bin/bash
# validate-hardened-image.sh

IMAGE=$1

echo "=== Validation de l'image durcie : $IMAGE ==="

# 1. Scanner les vulnérabilités
echo "1. Scan Trivy..."
trivy image --severity HIGH,CRITICAL "$IMAGE"

# 2. Vérifier l'utilisateur
echo "2. Vérification utilisateur..."
podman run --rm "$IMAGE" sh -c "id" 2>/dev/null || echo "Pas de shell - OK"

# 3. Tester read-only
echo "3. Test read-only filesystem..."
podman run --read-only --tmpfs /tmp --rm "$IMAGE" echo "OK" || echo "FAIL"

# 4. Vérifier la taille
echo "4. Taille de l'image..."
podman images "$IMAGE" --format "{{.Size}}"

echo ""
echo "Validation terminée."
```

---

## Dépannage

### Erreur : "permission denied" avec Distroless

**Problème :** Fichiers copiés appartiennent à root

**Solution :**
```dockerfile
# Utiliser --chown dans COPY
COPY --chown=nonroot:nonroot app.py .
```

---

### Erreur : "No module named 'xxx'" avec Distroless

**Problème :** Dépendances non copiées correctement

**Solution :**
```dockerfile
# Installer dans un répertoire cible
RUN pip install --target=/app/dependencies -r requirements.txt

# Configurer PYTHONPATH
ENV PYTHONPATH=/app/dependencies
```

---

### Impossible de déboguer (pas de shell)

**Solution 1 : Utiliser la variante :debug (temporaire)**
```dockerfile
FROM gcr.io/distroless/python3-debian12:debug
```

**Solution 2 : Ajouter des logs dans l'application**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Solution 3 : Utiliser un conteneur ephemeral**
```bash
podman debug myapp:distroless
```

---

### Chainguard : "authentication required"

**Problème :** Images Enterprise nécessitent authentification

**Solution :**
```bash
# Utiliser les images publiques gratuites
cgr.dev/chainguard/python:latest  # Gratuit

# Pour les images Enterprise (payant)
docker login cgr.dev
```

---

## Ressources

### Documentation officielle

- **Docker Hardened Images (dhi.io)** : https://docs.docker.com/dhi/
- **Docker Hardened Images GitHub** : https://github.com/docker-hardened-images
- **Google Distroless** : https://github.com/GoogleContainerTools/distroless
- **Chainguard Images** : https://www.chainguard.dev/chainguard-images
- **Red Hat UBI** : https://catalog.redhat.com/software/containers/explore
- **Iron Bank** : https://registry1.dso.mil

### Outils de sécurité

- **Trivy** : https://github.com/aquasecurity/trivy
- **Cosign** (signatures) : https://github.com/sigstore/cosign
- **Grype** : https://github.com/anchore/grype
- **Syft** (SBOM) : https://github.com/anchore/syft

### Conformité

- **PCI-DSS** : https://www.pcisecuritystandards.org/
- **HIPAA** : https://www.hhs.gov/hipaa
- **FedRAMP** : https://www.fedramp.gov/
- **DISA STIG** : https://public.cyber.mil/stigs/

---

## Conclusion

Les images durcies sont essentielles pour :
- ✅ Réduire drastiquement les vulnérabilités
- ✅ Conformité réglementaire
- ✅ Sécurité en profondeur
- ✅ Audits de sécurité simplifiés

**Recommandation générale :** Commencez avec **dhi.io (Docker Hardened Images)** (gratuit, zéro CVE, maintenance officielle Docker, open source Apache 2.0). Migrez vers une solution payante (DHI Enterprise ou Chainguard Enterprise) uniquement si vous avez besoin de SLA contractuels, conformité FIPS ou support 24/7.
