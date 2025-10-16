#!/bin/bash

echo "Exemples de limitation de ressources"

echo "1. Limiter CPU:"
podman run -d --name cpu-limited --cpus="0.5" nginx:alpine

echo "2. Limiter memoire:"
podman run -d --name mem-limited --memory=100m nginx:alpine

echo "3. Limiter processus:"
podman run -d --name pids-limited --pids-limit=10 nginx:alpine

echo ""
echo "Verification:"
podman stats --no-stream
