# Formation Podman - Workshop Complet

![ShellCheck](https://github.com/aboigues/podman-workshop/workflows/ShellCheck/badge.svg)
![Test Podman Workshop](https://github.com/aboigues/podman-workshop/workflows/Test%20Podman%20Workshop/badge.svg)
![Markdown Lint](https://github.com/aboigues/podman-workshop/workflows/Markdown%20Lint/badge.svg)
![Deprecation Check](https://github.com/aboigues/podman-workshop/workflows/Deprecation%20Check/badge.svg)

Formation complete et pratique sur Podman : de la conteneurisation de base au deploiement sur AWS.

## 🎓 Approche pédagogique : Learning by Doing

**Nouveau !** Ce workshop adopte une approche d'apprentissage progressif où vous **écrivez vos propres commandes** au lieu de copier-coller des solutions.

### Pourquoi cette approche ?
- ✍️ **Apprentissage actif** : Écrire les commandes vous-même renforce la compréhension
- 🎯 **Validation automatique** : Chaque exercice vérifie que vos commandes sont correctes
- 💡 **Indices progressifs** : Système d'aide à 3 niveaux pour vous guider sans donner la réponse
- ✅ **Feedback immédiat** : Validez vos exercices et voyez votre progression

### Structure des exercices

Chaque exercice contient :
- 📋 **README.md** : Énoncé détaillé avec objectifs et contexte
- ✏️ **Fichiers à compléter** : Commandes avec placeholders à remplir
- ✅ **Script de validation** : Vérifie automatiquement votre travail
- 💡 **Indices progressifs** : Aide à 3 niveaux si vous êtes bloqué
- 🔐 **Solutions complètes** : À consulter en dernier recours

## Sommaire des TPs

| TP | Titre | Niveau | Durée | Contenu |
|----|-------|--------|-------|---------|
| [TP1](TP1-conteneurs-simples/) | Conteneurs Simples | Débutant | 2h30 | Lancement, logs, gestion |
| [TP2](TP2-dockerfile/) | Dockerfile & Images | Intermédiaire | 2h30 | Images personnalisées |
| [TP3](TP3-compose/) | Podman Compose | Intermédiaire | 3h30 | Multi-services, orchestration |
| [TP4](TP4-systemd/) | Systemd | Avancé | 3h30 | Automatisation, services |
| [TP5A](TP5A-securite/) | Sécurité | Avancé | 2h30 | Rootless, SELinux, scan |
| [TP5B](TP5B-aws/) | AWS | Avancé | 3h30 | EC2, Terraform, cloud |
| [TP6](TP6-projet-complet/) 🎁 | **Projet Complet** | **Expert** | **3h** | **Stack complète bout-en-bout** |

**Total : 21 heures** de formation pratique et approfondie

## 🚀 Quick Start

### 1. Lire le guide d'apprentissage
```bash
cat GUIDE-APPRENTISSAGE.md
```

### 2. Vérifier les prérequis
```bash
./scripts/check-prerequisites.sh
```

### 3. Commencer votre premier exercice
```bash
cd TP1-conteneurs-simples/exercices/exercice-01

# Lire l'énoncé
cat README.md

# Compléter les commandes
nano commandes.sh

# Exécuter vos commandes
./commandes.sh

# Valider votre travail
./validation.sh
```

### 4. Si vous êtes bloqué
```bash
# Consulter les indices progressifs
cat indices.md

# En dernier recours : voir la solution
cat ../../solutions/exercice-01-solution.sh
```

## Prerequis

### Logiciels requis
- Podman >= 4.0
- Git >= 2.0
- Systeme Linux : Ubuntu 20.04+, RHEL 8+, Fedora 35+

### Ressources systeme
- 4 GB RAM minimum (8 GB recommande)
- 20 GB espace disque libre
- Acces sudo pour certains exercices

### Pour TP5B (AWS)
- Compte AWS
- AWS CLI v2
- Terraform >= 1.0 (optionnel)

## 📁 Structure du projet

```
podman-workshop/
├── GUIDE-APPRENTISSAGE.md           # 📚 Guide complet de la méthode d'apprentissage
├── lib/                             # 🛠️ Utilitaires de validation
│   └── validation-utils.sh
├── TP1-conteneurs-simples/          # Niveau Débutant
│   └── exercices/
│       ├── exercice-01/             # Lancer un conteneur
│       │   ├── README.md            # 📋 Énoncé
│       │   ├── commandes.sh         # ✏️ À compléter
│       │   ├── validation.sh        # ✅ Validation
│       │   └── indices.md           # 💡 Aide progressive
│       ├── exercice-02/             # Consulter les logs
│       ├── exercice-03/             # Cycle de vie
│       └── exercice-04/             # Mode interactif
├── TP2-dockerfile/                  # Niveau Intermédiaire
│   └── exercices/
│       ├── exercice-01-python/      # Dockerfile Python Flask
│       ├── exercice-02-go-multistage/ # Multi-stage builds
│       └── exercice-03-nginx/       # Nginx personnalisé
├── TP3-compose/                     # Niveau Intermédiaire
│   └── exercices/
│       └── exercice-01-web-db/      # Stack Web + DB
├── TP4-systemd/                     # Niveau Avancé
├── TP5A-securite/                   # Niveau Avancé
├── TP5B-aws/                        # Niveau Avancé
├── ressources/
│   └── cheatsheet.md                # Référence rapide
└── scripts/                         # Scripts utilitaires
    ├── check-prerequisites.sh
    ├── test-all.sh
    └── cleanup-all.sh
```

## 🛠️ Scripts utilitaires

```bash
./scripts/check-prerequisites.sh    # Vérifier les prérequis
./scripts/cleanup-all.sh            # Nettoyer tous les conteneurs/images

# Dans chaque exercice
./commandes.sh                      # Exécuter vos commandes
./validation.sh                     # Valider votre travail
./validation.sh --cleanup           # Nettoyer les ressources de l'exercice
```

## 🎯 Parcours d'apprentissage recommandé

### TP1 - Conteneurs Simples (2h30) - Débutant
Documentation complète avec explications ligne par ligne de chaque commande
- Exercice 1 : Lancer votre premier conteneur
- Exercice 2 : Consulter les logs
- Exercice 3 : Gérer le cycle de vie
- Exercice 4 : Mode interactif

### TP2 - Dockerfile (2h30) - Intermédiaire
3 exemples fonctionnels avec Dockerfile commentés
- Exemple 1 : Application Python Flask
- Exemple 2 : Multi-stage builds (Go)
- Exemple 3 : Nginx personnalisé

### TP3 - Podman Compose (3h30) - Intermédiaire
Documentation exhaustive (1000+ lignes) avec 6 exemples avancés et 4 exercices
- Structure complète d'un docker-compose.yml expliquée
- 6 exemples avancés (env files, build args, scaling, profils, healthchecks, ressources)
- 4 exercices pratiques guidés
- Guide de résolution de 8 problèmes courants

### TP4 - Systemd (3h30) - Avancé
Documentation complète (1100+ lignes) sur l'intégration Podman + systemd
- Structure des unit files systemd
- Mode user vs mode system
- 6 exemples avancés (healthcheck, dépendances, timers, socket activation)
- Gestion des dépendances entre services

### TP5A - Sécurité (2h30) - Avancé
Guide complet de sécurité (935 lignes)
- Mode rootless et user namespaces
- Capabilities Linux
- SELinux et AppArmor
- Scan de vulnérabilités (Trivy, Clair, Grype)
- Gestion des secrets
- Bonnes pratiques de sécurité

### TP5B - AWS (3h30) - Avancé
Déploiement cloud avec Terraform (760 lignes)
- Configuration AWS CLI
- Déploiement manuel sur EC2
- Infrastructure as Code avec Terraform
- Gestion des coûts et optimisation
- Bonnes pratiques AWS

### 🎁 TP6 - Projet Complet (3h) - Expert ⭐
**TP Bonus : Intégration complète de tous les concepts**
Stack DevOps complète avec 7 services orchestrés (940+ lignes)
- **Application réelle** : Frontend React + API Node.js + PostgreSQL + Redis
- **Infrastructure** : Reverse proxy Nginx avec SSL/TLS
- **Monitoring** : Prometheus + Grafana avec dashboards
- **Automatisation** : Services systemd pour auto-start
- **Sécurité** : Rootless, secrets, healthchecks, scan vulnérabilités
- **Déploiement** : Scripts automatisés + Terraform AWS (bonus)

**Concepts intégrés :** Tous les TP1 à TP5B dans un projet de bout en bout !

**Durée totale estimée : 21 heures**

*Note : Les durées sont estimées pour une compréhension approfondie incluant la lecture de la documentation,
la réalisation des exercices, et l'expérimentation personnelle. Pour un survol rapide, comptez environ 60%
de ces durées (~13h).*

## Licence

MIT License - voir [LICENSE](LICENSE)
