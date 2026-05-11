#!/bin/bash

# Script de gestión de usuarios para DevOps
# Uso: ./manage_users.sh [crear|eliminar|listar]

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

crear_usuario() {
    local username=$1
    if id "$username" &>/dev/null; then
        echo -e "${COLOR_RED}❌ Usuario $username ya existe${COLOR_RESET}"
    else
        sudo useradd -m -s /bin/bash "$username"
        echo "$username:TempPass123" | sudo chpasswd
        sudo usermod -aG wheel "$username"
        echo -e "${COLOR_GREEN}✅ Usuario $username creado correctamente${COLOR_RESET}"
    fi
}

eliminar_usuario() {
    local username=$1
    if id "$username" &>/dev/null; then
        sudo userdel -r "$username"
        echo -e "${COLOR_GREEN}✅ Usuario $username eliminado${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}❌ Usuario $username no existe${COLOR_RESET}"
    fi
}

listar_usuarios() {
    echo -e "\n📋 USUARIOS EN EL SISTEMA:\n"
    cut -d: -f1 /etc/passwd | grep -E "^(ec2-user|cloudshell-user|ana|juan|luis|maria|pedro)" | sort
}

case $1 in
    crear)
        if [ -z "$2" ]; then
            echo "Uso: ./manage_users.sh crear <username>"
        else
            crear_usuario "$2"
        fi
        ;;
    eliminar)
        if [ -z "$2" ]; then
            echo "Uso: ./manage_users.sh eliminar <username>"
        else
            eliminar_usuario "$2"
        fi
        ;;
    listar)
        listar_usuarios
        ;;
    *)
        echo "=========================================="
        echo "  SCRIPT DE GESTIÓN DE USUARIOS"
        echo "=========================================="
        echo ""
        echo "Uso: $0 [comando] [opciones]"
        echo ""
        echo "Comandos disponibles:"
        echo "  crear <username>   - Crear un nuevo usuario"
        echo "  eliminar <username> - Eliminar un usuario"
        echo "  listar             - Listar usuarios del sistema"
        echo ""
        echo "Ejemplos:"
        echo "  $0 crear ana"
        echo "  $0 eliminar ana"
        echo "  $0 listar"
        ;;
esac
