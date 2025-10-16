# Application Python Flask

Application web complete avec API REST.

## Build
```bash
podman build -t python-app .
```

## Run
```bash
podman run -d --name python-app -p 5000:5000 python-app
```

## Test
```bash
curl http://localhost:5000
curl http://localhost:5000/api/info
curl http://localhost:5000/api/health
```

## Stop
```bash
podman stop python-app
podman rm python-app
```
