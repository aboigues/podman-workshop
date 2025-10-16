# Formation Podman - Workshop Complet

Formation complete et pratique sur Podman : de la conteneurisation de base au deploiement sur AWS.

## Tous les fichiers sont prets a l'emploi

Chaque TP contient :
- Code source complet et fonctionnel
- Scripts de test automatises
- Solutions detaillees
- Documentation claire

## Sommaire des TPs

| TP | Titre | Niveau | Contenu |
|----|-------|--------|---------|
| [TP1](TP1-conteneurs-simples/) | Conteneurs Simples | Debutant | Lancement, logs, gestion |
| [TP2](TP2-dockerfile/) | Dockerfile & Images | Intermediaire | Images personnalisees |
| [TP3](TP3-compose/) | Podman Compose | Intermediaire | Multi-services |
| [TP4](TP4-systemd/) | Systemd | Avance | Automatisation |
| [TP5A](TP5A-securite/) | Securite | Avance | Rootless, SELinux, scan |
| [TP5B](TP5B-aws/) | AWS | Avance | EC2, ECS, Terraform |

## Quick Start

```bash
# 1. Verifier les prerequis
./scripts/check-prerequisites.sh

# 2. Tester que tout fonctionne
./scripts/test-all.sh

# 3. Commencer TP1
cd TP1-conteneurs-simples
./exercices/demo-complete.sh
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

## Structure du projet

```
podman-workshop/
├── TP1-conteneurs-simples/
├── TP2-dockerfile/
├── TP3-compose/
├── TP4-systemd/
├── TP5A-securite/
├── TP5B-aws/
└── scripts/
```

## Scripts utilitaires

```bash
./scripts/check-prerequisites.sh    # Verifier prerequis
./scripts/test-all.sh               # Tester tous les TPs
./scripts/cleanup-all.sh            # Nettoyer
./scripts/test-tp.sh TP1            # Tester un TP specifique
```

## Licence

MIT License - voir [LICENSE](LICENSE)
