# WebApp avec Base de Donnees

Application PHP avec PostgreSQL.

## Demarrer
```bash
podman-compose up -d
```

## Acceder
- Application : http://localhost:8080

## Logs
```bash
podman-compose logs -f web
podman-compose logs -f database
```

## Arreter
```bash
podman-compose down -v
```
