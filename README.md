# Formation Podman - Workshop Complet

![ShellCheck](https://github.com/aboigues/podman-workshop/workflows/ShellCheck/badge.svg)
![Test Podman Workshop](https://github.com/aboigues/podman-workshop/workflows/Test%20Podman%20Workshop/badge.svg)
![Markdown Lint](https://github.com/aboigues/podman-workshop/workflows/Markdown%20Lint/badge.svg)

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

| TP | Titre | Niveau | Contenu |
|----|-------|--------|---------|
| [TP1](TP1-conteneurs-simples/) | Conteneurs Simples | Debutant | Lancement, logs, gestion |
| [TP2](TP2-dockerfile/) | Dockerfile & Images | Intermediaire | Images personnalisees |
| [TP3](TP3-compose/) | Podman Compose | Intermediaire | Multi-services |
| [TP4](TP4-systemd/) | Systemd | Avance | Automatisation |
| [TP5A](TP5A-securite/) | Securite | Avance | Rootless, SELinux, scan |
| [TP5B](TP5B-aws/) | AWS | Avance | EC2, ECS, Terraform |

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

1. **TP1 - Conteneurs Simples** (2h) - Débutant
   - Exercice 1 : Lancer votre premier conteneur
   - Exercice 2 : Consulter les logs
   - Exercice 3 : Gérer le cycle de vie
   - Exercice 4 : Mode interactif

2. **TP2 - Dockerfile** (3h) - Intermédiaire
   - Exercice 1 : Application Python Flask
   - Exercice 2 : Multi-stage builds (Go)
   - Exercice 3 : Nginx personnalisé

3. **TP3 - Podman Compose** (2h) - Intermédiaire
   - Exercice 1 : Stack Web + Base de données

4. **TP4 - Systemd** (2h) - Avancé
5. **TP5A - Sécurité** (2h) - Avancé
6. **TP5B - AWS** (3h) - Avancé

**Durée totale estimée : 14 heures**

## Licence

MIT License - voir [LICENSE](LICENSE)
