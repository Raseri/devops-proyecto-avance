# ─────────────────────────────────────────────────────────────────
# ETAPA 1 — BUILD
# Instala dependencias y compila el frontend
# ─────────────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

# netcat para el script wait-for-db
RUN apk add --no-cache netcat-openbsd

WORKDIR /app

# Copiar manifests primero (aprovecha cache de capas)
COPY package*.json ./
RUN npm ci --omit=dev

# Copiar todo el código fuente
COPY . .

# Compilar frontend si existe
RUN if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then \
      cd frontend && npm install && npm run build; \
    fi

# ─────────────────────────────────────────────────────────────────
# ETAPA 2 — PRODUCCIÓN (imagen ligera)
# Solo copia lo necesario para ejecutar la app
# ─────────────────────────────────────────────────────────────────
FROM node:18-alpine AS production

# netcat para el script wait-for-db
RUN apk add --no-cache netcat-openbsd

WORKDIR /app

# Copiar dependencias de producción ya instaladas
COPY --from=builder /app/node_modules ./node_modules

# Copiar código fuente y artefactos del build
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/server.js ./
COPY --from=builder /app/src ./src
COPY --from=builder /app/config ./config
COPY --from=builder /app/public ./public

# Script de espera hasta que la DB esté lista
COPY --from=builder /app/docker/wait-for-db.sh /wait-for-db.sh
RUN chmod +x /wait-for-db.sh

# Puerto del servidor
ENV PORT=3000
ENV NODE_ENV=production
EXPOSE 3000

# Healthcheck básico
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["/bin/sh", "/wait-for-db.sh"]
