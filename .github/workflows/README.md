# GitHub Actions Workflows

Ce répertoire contient les workflows GitHub Actions pour automatiser les tests et la validation du Podman Workshop.

## Workflows disponibles

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

Exécute tous les tests automatisés des TPs avec Podman.

- **Déclencheur:** Push, PR sur `main`, ou manuel
- **Jobs:**
  - **prerequisites**: Vérifie l'installation de Podman et des outils nécessaires
  - **test-tp1**: Tests du TP1 (Conteneurs simples)
  - **test-tp2**: Tests du TP2 (Dockerfiles)
  - **test-tp3**: Tests du TP3 (Podman Compose)
  - **test-security-scripts**: Tests des scripts de sécurité du TP5A

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

### ShellCheck
Aucune configuration spécifique. Utilise les règles par défaut avec sévérité "warning".

### Markdown Lint
Configuration dans `.markdownlint.json` :
- Longueur de ligne : 120 caractères (flexible pour code et tableaux)
- HTML autorisé (MD033)
- Headings multiples autorisés (MD024, MD025)
- Style de liste ordonné

## Utilisation locale

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
![ShellCheck](https://github.com/aboigues/podman-workshop/workflows/ShellCheck/badge.svg)
![Test Podman Workshop](https://github.com/aboigues/podman-workshop/workflows/Test%20Podman%20Workshop/badge.svg)
![Markdown Lint](https://github.com/aboigues/podman-workshop/workflows/Markdown%20Lint/badge.svg)
```

## Dépannage

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

## Contribution

Lors de l'ajout de nouveaux scripts ou TPs :

1. Ajouter les tests appropriés dans les workflows
2. Vérifier que les scripts ont les permissions d'exécution
3. Tester localement avant de pusher
4. Consulter les résultats dans l'onglet Actions de GitHub

## Ressources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ShellCheck](https://www.shellcheck.net/)
- [markdownlint](https://github.com/DavidAnson/markdownlint)
- [Podman Documentation](https://docs.podman.io/)
