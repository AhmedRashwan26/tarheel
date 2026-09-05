#!/bin/bash
# ==============================================================================
# Tarheel Platform - Automatic Evolution API Installer for Hetzner
# ==============================================================================

set -e

echo "🚀 [1/4] Starting Evolution API Installation on Hetzner..."

# Detect Server Public IP
SERVER_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || echo "localhost")
echo "🌐 Detected Server IP: $SERVER_IP"

# Update .env with detected IP
if [ -f .env ]; then
    sed -i "s|YOUR_HETZNER_IP|$SERVER_IP|g" .env
fi

# Detect Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE="docker-compose"
else
    echo "📦 Installing Docker and Docker Compose..."
    apt update && apt install -y docker.io docker-compose-plugin
    systemctl enable --now docker
    COMPOSE="docker compose"
fi

# Launch Containers
echo "🐳 [2/4] Starting Evolution API with PostgreSQL and Redis..."
$COMPOSE pull
$COMPOSE down --remove-orphans || true
$COMPOSE up -d

echo "⏳ [3/4] Waiting 12 seconds for Database & API initialization..."
sleep 12

# Create Tarheel Instance
echo "📲 [4/4] Creating 'tarheel' WhatsApp Instance..."
API_KEY="Tarheel_Secure_Evolution_Key_2026"

curl -s -X POST "http://localhost:8080/instance/create" \
  -H "Content-Type: application/json" \
  -H "apikey: $API_KEY" \
  -d '{
    "instanceName": "tarheel",
    "token": "tarheel_token_2026",
    "qrcode": true,
    "integration": "WHATSAPP-BAILEYS"
  }' > /dev/null || true

echo ""
echo "=================================================================="
echo "🎉 Evolution API is now LIVE on your Hetzner Server!"
echo "=================================================================="
echo "🌐 API Base URL:  http://$SERVER_IP:8080"
echo "📚 API Docs / Swagger: http://$SERVER_IP:8080/docs"
echo "🔑 API Key:       $API_KEY"
echo ""
echo "📲 لمسح رمز الـ QR Code وربط رقم الواتساب مباشرة:"
echo "👉 افتح هذا الرابط في متصفحك:"
echo "   http://$SERVER_IP:8080/instance/connect/tarheel"
echo "=================================================================="
