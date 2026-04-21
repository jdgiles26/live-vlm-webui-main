#!/bin/bash
# Verify the custom container setup is complete and working

set -e

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

echo "════════════════════════════════════════════════════════════════"
echo "VERIFYING CUSTOM CONTAINER SETUP"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check Docker
echo "Checking Docker..."
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker not found"
    exit 1
fi
echo "✓ Docker is installed"

if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker daemon not running"
    exit 1
fi
echo "✓ Docker daemon is running"

# Check Docker Compose
echo ""
echo "Checking Docker Compose..."
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Docker Compose not found"
    exit 1
fi
echo "✓ Docker Compose is installed"

# Check files
echo ""
echo "Checking setup files..."
files_needed=(
    "$PROJECT_ROOT/Dockerfile.custom"
    "$PROJECT_ROOT/docker-compose.custom.yml"
    "$PROJECT_ROOT/.dockerignore"
    "$PROJECT_ROOT/CUSTOM_BUILD_GUIDE.md"
    "$PROJECT_ROOT/QUICK_COMMANDS.sh"
    "$SCRIPTS_DIR/start_custom.sh"
)

for file in "${files_needed[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing: $file"
        exit 1
    fi
    echo "✓ $(basename "$file")"
done

# Check image
echo ""
echo "Checking built image..."
if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "live-vlm-webui:custom"; then
    echo "✓ Image 'live-vlm-webui:custom' exists"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "live-vlm-webui:custom"
else
    echo "⚠️  Image 'live-vlm-webui:custom' not found (will be built on first run)"
fi

# Check source code
echo ""
echo "Checking source code..."
src_files=(
    "$PROJECT_ROOT/src/live_vlm_webui/server.py"
    "$PROJECT_ROOT/src/live_vlm_webui/video_processor.py"
    "$PROJECT_ROOT/src/live_vlm_webui/static/index.html"
)

for file in "${src_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing source: $file"
        exit 1
    fi
    echo "✓ $(basename "$file")"
done

# Summary
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ SETUP VERIFICATION COMPLETE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Your custom container is ready to use!"
echo ""
echo "Next steps:"
echo "  1. Start:  ./scripts/start_custom.sh"
echo "  2. Access: https://localhost:8090"
echo "  3. Model:  docker exec ollama ollama pull llama3.2-vision:11b"
echo ""
echo "For more info: cat CUSTOM_BUILD_GUIDE.md"
echo ""
