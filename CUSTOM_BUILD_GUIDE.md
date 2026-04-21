# Live VLM WebUI - Custom Local Build Guide

## Overview

Your Live VLM WebUI application has been containerized while **preserving all your custom MDG/NVIDIA UI features and code modifications**. The key difference from pulling pre-built images:

- ✅ **Builds from YOUR local source code** (not registry pulls)
- ✅ **Preserves all custom modifications** in `server.py`, `video_processor.py`, and UI
- ✅ **Easy rebuild** after code changes
- ✅ **Supports multiple backends** (Ollama, NVIDIA NIM)
- ✅ **Multi-platform** (PC/DGX Spark x86_64, Jetson Orin/Thor ARM64)

## Quick Start

### Option 1: Ollama Backend (Easiest - No API Keys)

```bash
# Build and start the application
cd /path/to/live-vlm-webui
./scripts/start_custom.sh

# Pull a vision model (in another terminal)
docker exec ollama ollama pull llama3.2-vision:11b

# Access the UI
# Open: https://localhost:8090
# Accept SSL warning (self-signed certificate)
```

### Option 2: NVIDIA NIM Backend (Advanced)

```bash
# Set your NGC API key
export NGC_API_KEY="nvapi-YOUR_KEY_HERE"

# Start with NIM backend
./scripts/start_custom.sh --nim

# Access the UI
# Open: https://localhost:8090
```

### Option 3: Direct Docker Compose Commands

```bash
# Build and start with Ollama
docker compose -f docker-compose.custom.yml --profile ollama up --build

# Or skip build (use existing image)
docker compose -f docker-compose.custom.yml --profile ollama up

# View logs
docker compose -f docker-compose.custom.yml logs -f live-vlm-webui

# Stop services
docker compose -f docker-compose.custom.yml down
```

## Rebuilding After Code Changes

Any modifications you make to your source code (`src/`, `static/`, etc.) are preserved and **automatically included in rebuilds**:

```bash
# Rebuild the image with your latest code changes
./scripts/start_custom.sh

# Or rebuild without starting
docker compose -f docker-compose.custom.yml --profile ollama build --progress=plain
```

## File Structure

```
live-vlm-webui/
├── Dockerfile.custom                 # 👈 Custom image (builds YOUR code)
├── .dockerignore                     # Optimization: excludes unnecessary files
├── docker-compose.custom.yml         # 👈 Custom compose (local build profiles)
│
├── src/
│   └── live_vlm_webui/
│       ├── server.py                 # Your custom modifications preserved
│       ├── video_processor.py        # Your custom features preserved
│       ├── gpu_monitor.py
│       ├── rtsp_track.py
│       ├── vlm_service.py
│       └── static/                   # Your MDG/NVIDIA UI preserved
│
├── scripts/
│   └── start_custom.sh               # 👈 Convenient startup script
│
├── docker/
│   └── (original Dockerfile copies - for reference)
│
├── requirements.txt                  # All dependencies
├── pyproject.toml
└── ...
```

## How It Works

### Traditional Approach (Registry Pull) - ❌ Loses Your Code
```
docker pull ghcr.io/nvidia-ai-iot/live-vlm-webui:latest
  ↓
Runs pre-built image from GitHub registry
  ↓
Your custom MDG UI and code changes are LOST
```

### Custom Local Build - ✅ Preserves Your Code
```
docker build -f Dockerfile.custom -t live-vlm-webui:custom .
  ↓
Copies YOUR entire source tree into image
  ↓
Installs all dependencies
  ↓
Your custom code runs inside container
  ↓
Rebuild anytime: all your modifications are included
```

## Configuration

### Environment Variables

Edit `docker-compose.custom.yml` or pass via `docker run -e`:

```yaml
environment:
  - PYTHONUNBUFFERED=1                    # Unbuffered Python output
  - LIVE_VLM_DEFAULT_MODEL=llava:7b       # Default model (Ollama format)
  - LIVE_VLM_API_BASE=http://localhost:11434/v1  # VLM backend URL
  - LIVE_VLM_PROCESS_EVERY=30             # Process every Nth frame
```

### VLM Backends

#### Ollama (Local, Free)
- Requires: Ollama installed on your system
- Port: 11434
- Models: https://ollama.com/search?c=vision

#### NVIDIA NIM (Production)
- Requires: NGC API key
- Port: 8000
- Models: Cosmos-Reason1-7B (multi-arch)

#### vLLM (High Performance)
- Requires: Manual setup
- Port: 8000

## Troubleshooting

### Build Fails
```bash
# Clear Docker build cache and rebuild
docker system prune -a
./scripts/start_custom.sh
```

### Container Won't Start
```bash
# Check logs
docker compose -f docker-compose.custom.yml logs live-vlm-webui

# Common issues:
# - Ollama not running: docker compose up ollama
# - Port 8090 in use: docker ps (find what's using it)
# - SSL cert issues: rm cert.pem key.pem && rebuild
```

### Webcam Not Working
- Use HTTPS: ✅ (built-in with SSL certs)
- Accept self-signed certificate warning
- Allow browser to access camera

### GPU Not Detected
```bash
# Add GPU runtime to container
docker run --gpus all ...

# Or in compose, add to service:
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

## Platform-Specific Instructions

### PC / DGX Spark (x86_64 / ARM64)

```bash
# Build and start
./scripts/start_custom.sh

# Or with NIM
export NGC_API_KEY=...
./scripts/start_custom.sh --nim
```

### Jetson Orin

```bash
# Build for Jetson Orin
./scripts/start_custom.sh --jetson-orin

# Requires: JetPack 5.x or 6.x with Docker runtime nvidia
```

### Jetson Thor

```bash
# Build for Jetson Thor
./scripts/start_custom.sh --jetson-thor

# Requires: JetPack 7.0+ (Python 3.12+)
```

### macOS (Docker Limitations)

Docker Desktop on macOS cannot access webcam directly. Use pip install instead:

```bash
# From source (recommended for macOS)
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
./scripts/start_server.sh
```

## Development Workflow

### Making Code Changes

1. Edit your files in `src/live_vlm_webui/`:
   - `server.py` - WebRTC server, API endpoints, VLM integration
   - `video_processor.py` - Video frame processing, ML analysis
   - `static/index.html` - Web UI

2. Rebuild the image:
   ```bash
   ./scripts/start_custom.sh
   ```

3. The container will use your updated code

### Live Reload (Optional)

For faster development iteration, mount source as volume (one-time setup):

```yaml
# In docker-compose.custom.yml, under live-vlm-webui service:
volumes:
  - ./src:/app/src:ro  # Read-only mount of source
  - /tmp/live-vlm-certs:/app/certs:rw
```

Then restart:
```bash
docker compose -f docker-compose.custom.yml --profile ollama up
```

Changes to Python files take effect after module reload (may require container restart).

## Stopping the Application

```bash
# Stop with Ctrl+C in the terminal where start_custom.sh runs
# Or in another terminal:
docker compose -f docker-compose.custom.yml down

# Verify stopped
docker ps | grep live-vlm
```

## Useful Commands

```bash
# View live logs
docker compose -f docker-compose.custom.yml logs -f live-vlm-webui

# Shell into container
docker compose -f docker-compose.custom.yml exec live-vlm-webui bash

# Rebuild without starting
docker compose -f docker-compose.custom.yml build

# List built images
docker images | grep live-vlm-webui

# Inspect image details
docker image inspect live-vlm-webui:custom

# Test image locally
docker run --gpus all -it live-vlm-webui:custom /bin/bash
```

## What's Inside the Container

```
Image: live-vlm-webui:custom (5.2GB)
Base: nvidia/cuda:12.4.1-runtime-ubuntu22.04

Contains:
  - Python 3.10
  - Your complete source code
  - All dependencies (aiohttp, aiortc, opencv, numpy, etc.)
  - FFmpeg libraries for video processing
  - WebRTC support (aiortc, libsrtp)
  - Self-signed SSL certificates
  - NVIDIA CUDA runtime (GPU support)
```

## Next Steps

1. **Test the build**: `./scripts/start_custom.sh` and access https://localhost:8090
2. **Pull a vision model**: `docker exec ollama ollama pull llama3.2-vision:11b`
3. **Add your features**: Edit code, rebuild with `./scripts/start_custom.sh`
4. **Deploy**: Push custom image to private registry, use in production

## Reference

- **Docker Compose Docs**: https://docs.docker.com/compose/
- **Ollama Models**: https://ollama.com/search?c=vision
- **NVIDIA NIM**: https://docs.nvidia.com/nim/
- **Live VLM WebUI Original**: https://github.com/nvidia-ai-iot/live-vlm-webui
