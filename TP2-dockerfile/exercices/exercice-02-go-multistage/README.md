# Exercice 2 : Multi-stage build avec Go

## 🎯 Objectifs
- Comprendre les multi-stage builds
- Optimiser la taille des images
- Séparer la compilation du runtime

## 📚 Concept
Un multi-stage build utilise plusieurs instructions `FROM` :
- **Stage 1** : Compilation (image avec outils de dev)
- **Stage 2** : Runtime (image minimaliste avec uniquement le binaire)

Avantage : Image finale ultra-légère (~10MB au lieu de ~400MB)

## 📝 Instructions

Créez un `Dockerfile` avec 2 stages :

### Stage 1 - Compilation
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /build
COPY app/ .
RUN go build -o main .
```

### Stage 2 - Runtime
```dockerfile
FROM alpine:3.18
WORKDIR /app
COPY --from=builder /build/main .
CMD ["./main"]
```

## ✅ Validation
```bash
./build.sh    # Construit l'image
./validation.sh
```

## 💡 Pourquoi multi-stage ?
- **Sans** : Image de 400MB (contient Go, outils, sources)
- **Avec** : Image de 10MB (uniquement le binaire)
