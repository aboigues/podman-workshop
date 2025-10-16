#!/bin/bash

IMAGE=${1:-nginx:alpine}

echo "Scan de securite: $IMAGE"

if command -v trivy &> /dev/null; then
    trivy image "$IMAGE"
else
    echo "Trivy non installe, utilisation via conteneur..."
    podman run --rm aquasec/trivy image "$IMAGE"
fi
