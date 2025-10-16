# Application Go avec Multi-Stage Build

Demonstration de l'optimisation avec multi-stage builds.

## Avantages
- Image finale ultra-legere (environ 10MB vs 400MB)
- Pas de dependances Go dans l'image finale
- Securite accrue

## Build
```bash
podman build -t go-app .
```

## Run
```bash
podman run -d --name go-app -p 8080:8080 go-app
```

## Test
```bash
curl http://localhost:8080
curl http://localhost:8080/api/info
```

## Comparer tailles
```bash
podman images | grep go-app
```
