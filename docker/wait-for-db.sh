#!/bin/sh
# =============================================================
# wait-for-db.sh — Espera a que MySQL esté listo antes de arrancar
# Docker no garantiza que el contenedor de la BD esté disponible
# aunque ya esté "corriendo". Este script lo resuelve.
# =============================================================

HOST="${DB_HOST:-db}"
PORT="${DB_PORT:-3306}"
MAX_TRIES=30
COUNT=0

echo "⏳ Esperando a que MySQL esté disponible en $HOST:$PORT..."

while ! nc -z "$HOST" "$PORT" 2>/dev/null; do
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$MAX_TRIES" ]; then
        echo "❌ MySQL no respondió después de $MAX_TRIES intentos. Abortando."
        exit 1
    fi
    echo "   Intento $COUNT/$MAX_TRIES — reintentando en 3 segundos..."
    sleep 3
done

echo "✅ MySQL está listo. Iniciando servidor Node.js..."
exec node server.js
