#!/bin/bash
# setup.sh
sudo apt update -y && sudo apt install git vim docker.io python3 -y
sudo usermod -aG docker ubuntu

# clean_logs.sh
cat > /home/ubuntu/clean_logs.sh << 'EOF'
#!/bin/bash
sudo find /var/log -type f -name "*.gz" -delete
EOF
chmod +x /home/ubuntu/clean_logs.sh

# Agregar crontab (evitar duplicados)
(crontab -l 2>/dev/null | grep -v "clean_logs.sh"; echo "0 2 * * * /home/ubuntu/clean_logs.sh") | crontab -

echo "=== Crontab actual ==="
crontab -l
echo "=== Configuracion completada! ==="
