# Simple Stack

Stack simple avec Nginx et Redis.

## Demarrer
```bash
podman-compose up -d
```

## Verifier
```bash
podman-compose ps
curl http://localhost:8080
```

## Logs
```bash
podman-compose logs
podman-compose logs -f web
```

## Arreter
```bash
podman-compose down
```
