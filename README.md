# ComfyUI Docker

[![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://www.docker.com/)
[![NVIDIA GPU](https://img.shields.io/badge/GPU-NVIDIA-green.svg)](https://www.nvidia.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Dockerized ComfyUI with full NVIDIA GPU support. One-command deployment for unlimited workflows.

<img width="2403" height="1243" alt="image" src="https://github.com/user-attachments/assets/97ae5e4f-7c49-47af-88a1-ab8f24812581" />

## 🚀 Features

- **Full GPU Acceleration** - NVIDIA CUDA support out of the box
- **Data Persistence** - Docker volumes for models and configurations  
- **Security First** - Non-root container execution
- **Auto-Setup** - Automatic directory structure creation
- **Customizable Build** - Dockerfile easily configurable for specific needs
- **Minimal Overhead** - Custom Python 3.12 build on Ubuntu 24.04

## 📋 Prerequisites

- Docker Engine 20.10+
- NVIDIA Container Toolkit
- NVIDIA GPU with compatible drivers

## 🛠️ Quick Start

### 1. Clone and Build
```bash
# Clone this repository
git clone https://github.com/EigenFunction32/ComfyUI-docker.git
cd ComfyUI-docker

# Build the image (must be run in the same directory as Dockerfile)
docker build -t comfyui-custom .

# or if you need to build from a different directory:

# 1. Build from specific path
docker build -t comfyui-custom /path/to/ComfyUI-docker

# 2. Or using git URL (no clone needed)
docker build -t comfyui-custom https://github.com/EigenFunction32/ComfyUI-docker.git
```

### 2. Create Data Volume
```bash
docker volume create comfyui-data
```

### 3. Run Container
```bash
docker run -d \
  --name comfyui \
  --restart unless-stopped \
  -p 8188:8188 \
  -v comfyui-data:/app/ComfyUI/user \
  --gpus all \
  comfyui-custom
```

### 4. Access UI
Open http://localhost:8188 in your browser.

## ⚙️ Customization

The Dockerfile is designed to be easily customizable:

```dockerfile
# Change Python version
ARG PYTHON_VERSION=3.12.3

# Change ComfyUI port
ARG COMFYUI_PORT=8188

# Add system dependencies
RUN apt-get install -y your-package-here

# Install additional Python packages
RUN pip install additional-package
```

Common customizations:
- **Python version** - Modify `PYTHON_VERSION` build arg
- **System packages** - Add to the `apt-get install` list
- **Python packages** - Add `pip install` commands after requirements
- **Port configuration** - Change `COMFYUI_PORT` environment variable

## ✅ Verification

Check if everything is working:

```bash
# View logs
docker logs comfyui

# Test GPU detection
docker exec comfyui python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}')"
```

## 💾 Data Management

Your models and configurations are stored in the Docker volume:

```bash
# Backup data
docker run --rm -v comfyui-data:/source -v $(pwd):/backup alpine tar czf /backup/comfyui-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore backup
docker run --rm -v comfyui-data:/target -v $(pwd):/backup alpine tar xzf /backup/comfyui-backup-YYYYMMDD.tar.gz -C /target
```

## 🔄 Updates

To update ComfyUI to the latest version:

```bash
# Stop container
docker stop comfyui

# Rebuild image
docker build -t comfyui-custom .

# Restart container
docker start comfyui
```

## 🗂️ Project Structure

```
ComfyUI-docker/
├── Dockerfile          # Multi-stage build with Python 3.12
├── README.md           # This file
└── LICENSE             # MIT License

Container structure:
/app/ComfyUI/
├── models/            # Checkpoints, LoRAs, VAEs
├── input/             # Input files
├── output/            # Generated images
└── user/              # Configurations (mounted volume)
```

## 🐛 Troubleshooting

### GPU Not Detected
```bash
# Verify NVIDIA Container Toolkit
docker run --rm --runtime=nvidia nvidia/cuda:11.8-base nvidia-smi
```

### Permission Issues
Ensure the `comfyui-data` volume is correctly mounted to `/app/ComfyUI/user`

### Port Already in Use
Change the host port:
```bash
docker run -p 8080:8188 ...  # Use port 8080 instead
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements.

---

**Happy Generating!** 🎨
