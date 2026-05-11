#!/bin/bash

LOG_DIR="/var/log"
DAYS_TO_KEEP=7

echo "========================================="
echo "LIMPIEZA DE LOGS AUTOMATIZADA"
echo "Fecha: $(date)"
echo "========================================="

# Limpiar logs del sistema
find $LOG_DIR -name "*.log" -type f -mtime +$DAYS_TO_KEEP -delete 2>/dev/null

# Limpiar logs de Docker (si existe)
if command -v docker &> /dev/null; then
    docker system prune -f --volumes 2>/dev/null
    echo "✅ Logs de Docker limpiados"
fi

echo "✅ Logs con más de $DAYS_TO_KEEP días eliminados"
echo "========================================="
