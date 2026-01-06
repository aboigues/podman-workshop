# Exercice 3 : Personnaliser une image Nginx

## 🎯 Objectifs
- Personnaliser une image existante
- Ajouter du contenu HTML personnalisé
- Configurer Nginx

## 📝 Instructions

Créez un Dockerfile qui :
1. Part de l'image `nginx:alpine`
2. Copie votre contenu HTML dans `/usr/share/nginx/html/`
3. (Optionnel) Copie une configuration nginx personnalisée

```dockerfile
FROM nginx:alpine
COPY html/ /usr/share/nginx/html/
# COPY nginx.conf /etc/nginx/nginx.conf  # optionnel
```

## 🚀 Testez
```bash
./build.sh
podman run -d -p 8080:80 mon-nginx:v1
curl http://localhost:8080
```

Votre page HTML personnalisée devrait s'afficher !
