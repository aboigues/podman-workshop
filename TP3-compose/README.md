# TP3 - Orchestration avec Podman Compose

## Objectifs
- Gerer des applications multi-services
- Configurer reseaux et volumes
- Implementer monitoring

## Exemples

Tous les exemples sont fonctionnels :

- `simple-stack/` - Stack web simple
- `webapp-db/` - Application web + PostgreSQL

## Quick Start

```bash
cd simple-stack
podman-compose up -d
curl http://localhost:8080
podman-compose down
```

## Commandes essentielles

```bash
podman-compose up -d       # Demarrer
podman-compose ps          # Lister
podman-compose logs -f     # Logs
podman-compose down        # Arreter
```

## Suite

[TP4 - Systemd](../TP4-systemd/)
