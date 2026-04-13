FROM node:18-alpine

# netcat-openbsd is needed by wait-for-db.sh for TCP port checking
RUN apk add --no-cache netcat-openbsd

WORKDIR /app

# Copy dependency manifests first (layer cache optimisation)
COPY package*.json ./

# Install all dependencies (dev too, since we may need build tools)
RUN npm install

# Copy application source code
COPY . .

# Build the frontend if it exists
RUN if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then \
      cd frontend && npm install && npm run build; \
    fi

# Copy and make the DB wait-script executable
COPY docker/wait-for-db.sh /wait-for-db.sh
RUN chmod +x /wait-for-db.sh

# Puerta del servidor — siempre 3000 dentro del contenedor
ENV PORT=3000
EXPOSE 3000

# Start via the wait script (holds until MySQL is ready, then runs node server.js)
CMD ["/bin/sh", "/wait-for-db.sh"]
