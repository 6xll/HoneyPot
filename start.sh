#!/bin/bash
# Quick start script for HoneyPot Security Monitoring Stack

set -e

echo "🍯 Cowrie HoneyPot Security Monitoring Stack"
echo "=============================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed."
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not available."
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if required directories exist
echo "📁 Checking directory structure..."
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Are you in the project root?"
    exit 1
fi

if [ ! -f "promtail-config.yaml" ]; then
    echo "❌ Error: promtail-config.yaml not found."
    exit 1
fi

if [ ! -d "grafana/provisioning" ]; then
    echo "❌ Error: grafana/provisioning directory not found."
    exit 1
fi

echo "✅ All required files found"
echo ""

# Ask user what to do
echo "What would you like to do?"
echo "1) Start the stack"
echo "2) Stop the stack"
echo "3) View logs"
echo "4) Check status"
echo "5) Reset everything (delete volumes)"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting the HoneyPot monitoring stack..."
        echo ""
        docker compose up -d
        echo ""
        echo "✅ Stack started successfully!"
        echo ""
        echo "📊 Access your services:"
        echo "   • Grafana:        http://localhost:3000 (admin/admin)"
        echo "   • VictoriaLogs:   http://localhost:9428"
        echo "   • Cowrie SSH:     localhost:2222"
        echo "   • Cowrie Telnet:  localhost:2223"
        echo ""
        echo "💡 Tip: Wait a few minutes for all services to start, then check Grafana"
        ;;
    2)
        echo ""
        echo "🛑 Stopping the stack..."
        docker compose down
        echo "✅ Stack stopped"
        ;;
    3)
        echo ""
        echo "📋 Showing logs (Ctrl+C to exit)..."
        docker compose logs -f
        ;;
    4)
        echo ""
        echo "📊 Service status:"
        docker compose ps
        echo ""
        echo "💾 Volume usage:"
        docker volume ls | grep -E "(cowrie|victorialogs|grafana)"
        ;;
    5)
        echo ""
        read -p "⚠️  This will DELETE all logs and data. Are you sure? [y/N]: " confirm
        if [[ $confirm == [yY] ]]; then
            echo "🗑️  Stopping and removing everything..."
            docker compose down -v
            echo "✅ Everything removed"
        else
            echo "Cancelled"
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
