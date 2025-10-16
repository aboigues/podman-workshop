# Nginx Custom

Serveur Nginx personnalise.

## Build
```bash
podman build -t nginx-custom .
```

## Run
```bash
podman run -d --name nginx-custom -p 8082:80 nginx-custom
```

## Test
```bash
curl http://localhost:8082
curl http://localhost:8082/health
```
