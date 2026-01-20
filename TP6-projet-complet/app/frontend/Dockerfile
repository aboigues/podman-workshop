# Stage 1: Build React App
FROM node:22.22.0-alpine AS builder

WORKDIR /app

# Arguments de build
ARG REACT_APP_API_URL
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le code source
COPY . .

# Build de production
RUN npm run build

# Stage 2: Servir avec Nginx
FROM nginx:alpine

# Copier la configuration Nginx custom
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copier les fichiers buildés depuis le stage précédent
COPY --from=builder /app/build /usr/share/nginx/html

# Ajuster les permissions pour l'utilisateur nginx existant
RUN chown -R nginx:nginx /usr/share/nginx/html

# Exposer le port
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Nginx démarre automatiquement (en root mais drop les privilèges pour les workers)
CMD ["nginx", "-g", "daemon off;"]
