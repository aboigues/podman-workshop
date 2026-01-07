# GitHub Actions Workflows

Ce répertoire contient les workflows GitHub Actions pour automatiser les tests et la validation du Podman Workshop.

## Workflows disponibles

### 🛡️ Trivy Security Scan
**Fichier:** `trivy-scan.yml`

Scanne les images Docker pour détecter les vulnérabilités de sécurité avec Trivy.

- **Déclencheur:** Push ou PR sur `main` avec modifications de Dockerfiles ou code applicatif
- **Path Filters Intelligents:** Ne scanne que les images affectées par les changements
- **Sévérité:** Rejette les vulnérabilités **CRITICAL** et **HIGH**
- **Jobs:**
  - **changes**: Détecte quels TPs ont été modifiés
  - **scan-tp2-images**: Scanne les images TP2 (python-app, go-app, nginx-custom)
  - **scan-tp3-images**: Scanne l'image webapp du TP3
  - **scan-tp6-images**: Scanne les images du projet complet (backend, frontend, nginx)
  - **scan-tp5a-images**: Scanne les exemples de sécurité du TP5A
- **Artifacts:** Les rapports de scan sont uploadés et disponibles pendant 30 jours
- **Mode:** `fail-fast: false` pour continuer même si une image échoue

### 🔍 ShellCheck
**Fichier:** `shellcheck.yml`

Vérifie la syntaxe et les bonnes pratiques de tous les scripts shell du projet.

- **Déclencheur:** Push ou PR sur `main` avec modifications de fichiers `.sh`
- **Actions:**
  - Analyse statique avec ShellCheck
  - Détection des erreurs courantes
  - Vérification des bonnes pratiques bash

### 🧪 Test Podman Workshop
**Fichier:** `test-podman.yml`

Exécute tous les tests automatisés des TPs avec Podman. **Amélioré avec détection intelligente des changements.**

- **Déclencheur:** Push, PR sur `main`, ou manuel
- **Path Filters Intelligents:** N'exécute que les tests nécessaires selon les fichiers modifiés
- **Jobs:**
  - **changes**: Détecte quels TPs ont été modifiés pour optimiser l'exécution
  - **prerequisites**: Vérifie l'installation de Podman et des outils nécessaires (si nécessaire)
  - **test-tp1**: Tests du TP1 (Conteneurs simples) - si TP1 modifié
  - **test-tp2**: Tests du TP2 (Dockerfiles) - si TP2 modifié
  - **test-tp3**: Tests du TP3 (Podman Compose) - si TP3 modifié
  - **test-security-scripts**: Tests des scripts de sécurité du TP5A - si TP5A modifié
  - **test-tp6**: Tests du TP6 (Projet complet) - si TP6 modifié

**Avantages des path filters:**
- ⚡ Exécution plus rapide (seulement les tests pertinents)
- 💰 Économie de ressources GitHub Actions
- 🎯 Feedback plus ciblé sur les changements

### 📝 Markdown Lint
**Fichier:** `markdown-lint.yml`

Vérifie la qualité et la cohérence des fichiers Markdown (README, documentation).

- **Déclencheur:** Push ou PR sur `main` avec modifications de fichiers `.md`
- **Configuration:** `.markdownlint.json`
- **Actions:**
  - Vérification de la syntaxe Markdown
  - Contrôle de la cohérence du formatage
  - Continue même en cas d'erreurs (non-bloquant)

## Configuration

### Trivy Security Scan
Configuration du scan de sécurité :
- **Sévérité bloquante:** CRITICAL, HIGH
- **Types de vulnérabilités:** OS packages et bibliothèques
- **Mode:** ignore-unfixed (ignore les vulnérabilités sans correctif disponible)
- **Format de sortie:** Table lisible + artifacts téléchargeables
- **Détection de changements:** Utilise `dorny/paths-filter@v2` pour optimiser l'exécution

### ShellCheck
Aucune configuration spécifique. Utilise les règles par défaut avec sévérité "warning".

### Markdown Lint
Configuration dans `.markdownlint.json` :
- Longueur de ligne : 120 caractères (flexible pour code et tableaux)
- HTML autorisé (MD033)
- Headings multiples autorisés (MD024, MD025)
- Style de liste ordonné

## Utilisation locale

### Scanner les images avec Trivy

```bash
# Installer Trivy
# Ubuntu/Debian
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# macOS
brew install aquasecurity/trivy/trivy

# Scanner une image Podman/Docker locale
podman build -t myapp:test -f Dockerfile .
trivy image myapp:test

# Scanner avec les mêmes paramètres que CI (only HIGH/CRITICAL)
trivy image --severity HIGH,CRITICAL --ignore-unfixed myapp:test

# Scanner et sauvegarder le rapport
trivy image --severity HIGH,CRITICAL --ignore-unfixed -o report.txt myapp:test

# Exemples pour les TPs du workshop
cd TP2-dockerfile/python-app
podman build -t python-app:test .
trivy image --severity HIGH,CRITICAL python-app:test

cd ../go-app
podman build -t go-app:test .
trivy image --severity HIGH,CRITICAL go-app:test

# Scanner le projet complet TP6
cd TP6-projet-complet
podman build -t backend:test -f app/backend/Dockerfile app/backend
trivy image --severity HIGH,CRITICAL backend:test
```

### Tester les scripts avant commit

```bash
# Vérifier les prérequis
bash scripts/check-prerequisites.sh

# Tester tous les TPs
bash scripts/test-all.sh

# Tester un TP spécifique
cd TP1-conteneurs-simples/exercices
bash quick-test.sh
```

### Vérifier la syntaxe des scripts

```bash
# Installer ShellCheck
sudo apt-get install shellcheck  # Ubuntu/Debian
brew install shellcheck          # macOS

# Vérifier un script
shellcheck scripts/check-prerequisites.sh

# Vérifier tous les scripts
find . -name "*.sh" -type f -exec shellcheck {} \;
```

### Vérifier les fichiers Markdown

```bash
# Installer markdownlint-cli
npm install -g markdownlint-cli

# Vérifier un fichier
markdownlint README.md

# Vérifier tous les fichiers
markdownlint '**/*.md' --ignore node_modules
```

## Badges de statut

Ajoutez ces badges dans votre README principal :

```markdown
![Trivy Security Scan](https://github.com/aboigues/podman-workshop/workflows/Trivy%20Security%20Scan/badge.svg)
![Test Podman Workshop](https://github.com/aboigues/podman-workshop/workflows/Test%20Podman%20Workshop/badge.svg)
![ShellCheck](https://github.com/aboigues/podman-workshop/workflows/ShellCheck/badge.svg)
![Markdown Lint](https://github.com/aboigues/podman-workshop/workflows/Markdown%20Lint/badge.svg)
```

## Dépannage

### Échec Trivy Security Scan

#### Vulnérabilités CRITICAL ou HIGH détectées
1. **Consulter le rapport Trivy** dans les artifacts du workflow
2. **Identifier les vulnérabilités:**
   - Nom du package vulnérable
   - CVE associé
   - Version affectée
   - Version corrigée disponible

3. **Corriger les vulnérabilités:**
   ```bash
   # Mettre à jour l'image de base dans le Dockerfile
   FROM node:18-alpine  # Au lieu de node:14

   # Ou mettre à jour les dépendances
   RUN apt-get update && apt-get upgrade -y

   # Ou spécifier des versions spécifiques des packages
   RUN pip install requests==2.31.0
   ```

4. **Vérifier localement:**
   ```bash
   podman build -t myapp:test .
   trivy image --severity HIGH,CRITICAL myapp:test
   ```

#### Échec du build de l'image
- Vérifier que le Dockerfile est valide
- S'assurer que tous les fichiers nécessaires sont dans le contexte de build
- Consulter les logs de build dans Actions

#### Timeout du scan
- Les images très volumineuses peuvent prendre du temps
- Vérifier si l'image peut être optimisée (multi-stage builds, moins de layers)

### Échec du job prerequisites
- Vérifier que Podman est correctement installé dans le runner
- Vérifier les permissions d'exécution des scripts

### Échec des tests TP
- Consulter les logs détaillés dans l'onglet Actions
- Reproduire localement avec les mêmes commandes
- Vérifier que les images Podman sont disponibles

### Échec ShellCheck
- Corriger les erreurs signalées
- Consulter https://www.shellcheck.net/ pour les explications
- Utiliser `# shellcheck disable=SCXXXX` si nécessaire (avec justification)

### Échec Markdown Lint
- Corriger le formatage selon les règles
- Ajuster `.markdownlint.json` si nécessaire
- Ce workflow est non-bloquant par défaut

### Les tests ne s'exécutent pas (skipped)
- Vérifier que les fichiers modifiés correspondent aux path filters
- En cas de doute, déclencher manuellement avec `workflow_dispatch`
- Consulter le job "changes" pour voir quels filtres ont été activés

## Contribution

Lors de l'ajout de nouveaux scripts ou TPs :

1. Ajouter les tests appropriés dans les workflows
2. Vérifier que les scripts ont les permissions d'exécution
3. Tester localement avant de pusher
4. Consulter les résultats dans l'onglet Actions de GitHub

## Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy - Vulnerability Scanner](https://aquasecurity.github.io/trivy/)
- [Trivy Action](https://github.com/aquasecurity/trivy-action)
- [Path Filter Action](https://github.com/dorny/paths-filter)
- [ShellCheck](https://www.shellcheck.net/)
- [markdownlint](https://github.com/DavidAnson/markdownlint)
- [Podman Documentation](https://docs.podman.io/)
- [Container Security Best Practices](https://sysdig.com/blog/dockerfile-best-practices/)
