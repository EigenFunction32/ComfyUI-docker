# ComfyUI Docker

[![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://www.docker.com/)
[![NVIDIA GPU](https://img.shields.io/badge/GPU-NVIDIA-green.svg)](https://www.nvidia.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Dockerized ComfyUI with full NVIDIA GPU support. One-command deployment for endless workflows with integrated ComfyUI Manager.

## 🚀 Features

- **Full GPU Acceleration** - NVIDIA CUDA support out of the box
- **ComfyUI Manager Pre-installed** - Manage custom nodes and models seamlessly
- **Multi-CUDA Version Support** - Compatible with CUDA 13.X, 12.X, 11.X and more
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
Open **http://localhost:8188** in your browser.

## Alternative Build Methods

If you need to build from a different directory:
```bash
# Build from specific path
docker build -t comfyui-custom /path/to/ComfyUI-docker

# Or using git URL (no clone needed)
docker build -t comfyui-custom https://github.com/EigenFunction32/ComfyUI-docker.git
```

## ⚙️ Customization

The Dockerfile is designed to be easily customizable for different hardware and requirements:

```dockerfile
# Change Python version
ARG PYTHON_VERSION=3.12.3

# Change ComfyUI port
ARG COMFYUI_PORT=8188

# Change PyTorch/CUDA version (see available versions below)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cuXXX

# Add system dependencies
RUN apt-get install -y your-package-here

# Install additional Python packages
RUN pip install additional-package
```

**Common customizations:**
- **Python version** - Modify `PYTHON_VERSION` build arg
- **PyTorch/CUDA version** - Change PyTorch installation command (see table below)
- **System packages** - Add to the `apt-get install` list
- **Python packages** - Add `pip install` commands after requirements
- **Port configuration** - Change `COMFYUI_PORT` environment variable

### Available PyTorch/CUDA Versions

| CUDA Version | PyTorch Command | Notes |
|--------------|-----------------|-------|
| **CUDA 12.9** | `pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu129` |
| **CUDA 12.8** | `pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128` | **Required for Blackwell GPUs (RTX 50xx)**. Requires NVIDIA 570+ drivers |
| **CUDA 12.1** | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121` | Standard for RTX 40/30 series |
| **CUDA 11.8** | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118` | Compatible with older GPUs |
| **CPU Only** | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu` | For systems without GPU |

**Community tested versions:**
Some Docker projects also report support for **CUDA 12.9** and **CUDA 13.0**. For these and other versions, check availability on the [official PyTorch website](https://pytorch.org/).

**Example for CUDA 12.8 (RTX 50xx):**
```dockerfile
# Replace the PyTorch installation line in Dockerfile:
RUN pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
```

**Important Note:** Ensure your NVIDIA drivers support the chosen CUDA version. For **GTX 10xx** GPUs, for example, a version like CUDA 12.6.3 is recommended. Check compatibility at [NVIDIA CUDA Documentation](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html).

## 📥 Loading Models

### Method 1: ComfyUI Manager (Recommended)
1. Access http://localhost:8188
2. Click **Manager** button in the interface
3. Use **Model Manage** to download models directly
4. Install custom nodes via **Custom Node Manager**

### Method 2: Docker Commands
```bash
# Copy models to volume
docker run --rm -v comfyui-data:/target -v $(pwd):/source alpine cp /source/model.safetensors /target/models/checkpoints/

# Verify models
docker run --rm -v comfyui-data:/data alpine find /data/models -name "*.safetensors"
```

### Folder Structure in Volume:
```
user/
├── models/
│   ├── checkpoints/     # Main models (.safetensors, .ckpt)
│   ├── vae/             # VAE models
│   ├── loras/           # LoRA models
│   ├── controlnet/      # ControlNet models
│   ├── clip/            # CLIP models
│   └── upscale_models/  # Upscaling models
├── input/               # Input files
└── output/              # Generated images
```

## 🔍 Accessing Volume Data

Docker volumes are not directly visible in the host filesystem. To access your data:

### Explore volume content:
```bash
# Enter the container
docker exec -it comfyui bash
ls -la /app/ComfyUI/user/

# Or use temporary container
docker run --rm -it -v comfyui-data:/data alpine ls -la /data
```

### Copy files to/from volume:
```bash
# Backup volume to current directory
docker run --rm -v comfyui-data:/source -v $(pwd):/backup alpine cp -r /source/* /backup/

# Restore files to volume  
docker run --rm -v comfyui-data:/target -v $(pwd):/source alpine cp -r /source/* /target/
```

## ✅ Verification

Check if everything is working:

```bash
# View logs
docker logs -f comfyui

# Test GPU detection
docker exec comfyui python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}'); print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}')"
```

## 💾 Data Management

Your models and configurations are stored in the Docker volume:

```bash
# Backup data (compressed)
docker run --rm -v comfyui-data:/source -v $(pwd):/backup alpine tar czf /backup/comfyui-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore backup
docker run --rm -v comfyui-data:/target -v $(pwd):/backup alpine tar xzf /backup/comfyui-backup-YYYYMMDD.tar.gz -C /target
```

## 🔄 Updates

To update ComfyUI to the latest version:

```bash
# Stop container
docker stop comfyui

# Rebuild image (from project directory)
cd ComfyUI-docker
docker build -t comfyui-custom .

# Restart container
docker start comfyui
```

## 🗂️ Project Structure

```
ComfyUI-docker/
├── Dockerfile          # Multi-stage build with Python 3.12 + ComfyUI Manager
├── README.md           # This file
└── LICENSE             # MIT License

Container structure:
/app/ComfyUI/
├── custom_nodes/
│   └── ComfyUI-Manager/  # Pre-installed manager
├── models/              # Checkpoints, LoRAs, VAEs
├── input/               # Input files
├── output/              # Generated images
└── user/                # Configurations (mounted volume)
```

## 🐛 Troubleshooting

### Build Issues
- **Error**: "Dockerfile not found" - Make sure you're in the correct directory
- **Error**: "Permission denied" - Ensure proper directory ownership in Dockerfile

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

### ComfyUI Manager Issues
If custom nodes fail to install, check that GitPython is properly installed in the container.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements.

---

**Happy Generating!** 🎨
