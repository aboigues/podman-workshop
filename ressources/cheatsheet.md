# Podman Cheatsheet

## Commandes de base

```bash
# Conteneurs
podman run -d --name NAME IMAGE
podman ps
podman ps -a
podman stop NAME
podman start NAME
podman rm NAME
podman logs NAME
podman exec -it NAME /bin/bash

# Images
podman images
podman build -t NAME .
podman pull IMAGE
podman push IMAGE
podman rmi IMAGE
podman inspect IMAGE

# Volumes
podman volume create NAME
podman volume ls
podman volume rm NAME
podman volume inspect NAME

# Reseaux
podman network create NAME
podman network ls
podman network rm NAME
podman network inspect NAME

# Compose
podman-compose up -d
podman-compose down
podman-compose ps
podman-compose logs -f

# Systemd
podman generate systemd --new --files --name NAME
systemctl --user daemon-reload
systemctl --user enable --now container-NAME.service

# Securite
podman run --cap-drop=ALL --cap-add=NET_RAW IMAGE
podman run --user 1000:1000 IMAGE
podman run --read-only IMAGE
podman run --memory=100m --cpus=0.5 IMAGE
```

## Dockerfile

```dockerfile
FROM image:tag
WORKDIR /app
COPY . .
RUN command
EXPOSE port
USER username
CMD ["executable"]
```

## docker-compose.yml

```yaml
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    networks:
      - mynetwork
volumes:
  myvolume:
networks:
  mynetwork:
```
