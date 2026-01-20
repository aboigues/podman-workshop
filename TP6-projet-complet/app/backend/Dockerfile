# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer toutes les dépendances (dev + prod)
RUN npm install

# Copier le code source
COPY . .

# Build de l'application (si TypeScript)
# RUN npm run build

# Stage 2: Runtime
FROM node:22-alpine

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copier seulement les dépendances de production
COPY package*.json ./
RUN npm install --only=production && \
    npm cache clean --force

# Copier le code depuis le builder
COPY --from=builder --chown=nodejs:nodejs /app/src ./src
# Si build TypeScript:
# COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Changer vers l'utilisateur non-root
USER nodejs

# Exposer le port
EXPOSE 4000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/api/health || exit 1

# Démarrer l'application
CMD ["node", "src/index.js"]
# Si build TypeScript: CMD ["node", "dist/index.js"]
