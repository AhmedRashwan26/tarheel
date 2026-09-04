#!/bin/bash
# ==============================================================================
# Tarheel Platform - Production Deployment Script for Hetzner Server
# ==============================================================================

set -e

echo "🚀 [1/5] Starting Tarheel Production Deployment..."

# Create required directories
mkdir -p uploads nginx/ssl

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found! Generating a secure default .env from .env.example..."
    cp .env.example .env
fi

# Build Flutter Web App if flutter CLI is available on host
if command -v flutter &> /dev/null; then
    echo "📱 [2/5] Building Flutter Web Application (Release Mode)..."
    cd tarheel_app
    flutter pub get
    flutter build web --release --base-href "/"
    cd ..
else
    echo "ℹ️  Flutter CLI not detected on host. Ensuring ./tarheel_app/build/web exists..."
    mkdir -p tarheel_app/build/web
fi

# Detect docker compose or docker-compose
if docker compose version &> /dev/null; then
    COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE="docker-compose"
else
    echo "📦 Installing docker compose..."
    apt update && apt install -y docker-compose-plugin docker-compose
    COMPOSE="docker compose"
fi

# Build and start Docker containers
echo "🐳 [3/5] Building and starting Docker Production Containers using $COMPOSE..."
$COMPOSE -f docker-compose.prod.yml down --remove-orphans || true
$COMPOSE -f docker-compose.prod.yml build
$COMPOSE -f docker-compose.prod.yml up -d

# Wait for API to be ready
echo "⏳ [4/5] Waiting for services to initialize..."
sleep 10

# Display running containers
echo "✅ [5/5] Deployment Finished Successfully!"
$COMPOSE -f docker-compose.prod.yml ps

echo "=================================================================="
echo "🎉 Tarheel Platform is now LIVE!"
echo "🌐 Web Application: http://<YOUR_SERVER_IP> or https://<YOUR_DOMAIN>"
echo "📚 API Swagger Docs: http://<YOUR_SERVER_IP>/api/docs"
echo "🔍 Health Check:     http://<YOUR_SERVER_IP>/api/health"
echo "=================================================================="
