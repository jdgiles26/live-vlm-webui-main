#!/bin/bash
# Start Live VLM WebUI from Custom Local Source (Preserves Your Code)
# This script builds and runs the containerized app with your custom MDG/NVIDIA UI features

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "=========================================="
echo "Live VLM WebUI - Custom Local Build"
echo "=========================================="
echo ""
echo "This script:"
echo "  1. Builds a Docker image from YOUR custom source code"
echo "  2. Preserves your MDG/NVIDIA UI and all custom features"
echo "  3. Runs with Ollama backend for local VLM inference"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Parse command line arguments
PROFILE="ollama"
NO_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --nim)
            PROFILE="nim"
            shift
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        --jetson-orin)
            PROFILE="${PROFILE}-jetson-orin"
            shift
            ;;
        --jetson-thor)
            PROFILE="${PROFILE}-jetson-thor"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --nim              Use NVIDIA NIM backend (requires NGC API key)"
            echo "  --jetson-orin      Build for Jetson Orin"
            echo "  --jetson-thor      Build for Jetson Thor"
            echo "  --no-build         Skip rebuild, use existing image"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  # Ollama (default, PC/DGX Spark)"
            echo "  $0"
            echo ""
            echo "  # NVIDIA NIM backend"
            echo "  export NGC_API_KEY=your-key-here"
            echo "  $0 --nim"
            echo ""
            echo "  # Jetson Orin with Ollama"
            echo "  $0 --jetson-orin"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "Configuration:"
echo "  Profile:     $PROFILE"
echo "  Build image: $NO_BUILD"
echo "  Project:     $PROJECT_ROOT"
echo ""

# Set NIM API key if using NIM profile
if [[ "$PROFILE" == *"nim"* ]]; then
    if [ -z "$NGC_API_KEY" ]; then
        echo "❌ NGC_API_KEY environment variable not set"
        echo ""
        echo "To use NVIDIA NIM backend:"
        echo "  1. Get API key from: https://org.ngc.nvidia.com/setup/api-key"
        echo "  2. Set it: export NGC_API_KEY=your-key-here"
        echo "  3. Re-run this script"
        exit 1
    fi
    echo "✓ NGC_API_KEY is set"
fi

# Build image if needed
if [ "$NO_BUILD" = false ]; then
    echo ""
    echo "📦 Building Docker image from your custom source..."
    echo "   (This preserves your MDG/NVIDIA UI and custom features)"
    echo ""
    
    cd "$PROJECT_ROOT"
    docker compose -f docker-compose.custom.yml --profile "$PROFILE" build --progress=plain
    
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
    echo "✓ Build successful"
else
    echo "⏭️  Skipping build (using existing image)"
fi

echo ""
echo "🚀 Starting services with profile: $PROFILE"
echo ""

cd "$PROJECT_ROOT"
docker compose -f docker-compose.custom.yml --profile "$PROFILE" up

echo ""
echo "=========================================="
echo "Shutdown complete"
echo "=========================================="
