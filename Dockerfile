FROM ubuntu:24.04 AS builder

ARG PYTHON_VERSION=3.12.3
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /build

# Build Python
RUN apt-get update && apt-get install -y \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev git ca-certificates

RUN wget -q https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar -xf Python-${PYTHON_VERSION}.tgz && cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations --prefix=/opt/python3.12 && \
    make -j$(nproc) && make install && \
    /opt/python3.12/bin/python3.12 -m pip install --upgrade pip

# Runtime
FROM ubuntu:24.04

ARG COMFYUI_PORT=8188
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/opt/python3.12/bin:${PATH}" \
    COMFYUI_PORT=${COMFYUI_PORT}

# Dipendenze sistema
RUN apt-get update && apt-get install -y \
    python3-full libssl3 zlib1g libbz2-1.0 libreadline8 \
    libsqlite3-0 libncurses6 tk libxml2 libxmlsec1 libffi8 \
    liblzma5 git curl wget ca-certificates ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/*

# Crea utente non-privilegiato
RUN groupadd -r comfyuser && useradd -r -g comfyuser -d /app comfyuser

WORKDIR /app
COPY --from=builder /opt/python3.12 /opt/python3.12

# Installa PyTorch e ComfyUI
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129 && \
    git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && pip install -r requirements.txt

# Crea directory user per il volume
RUN mkdir -p /app/ComfyUI/user && chown -R comfyuser:comfyuser /app/ComfyUI

# Esegui come utente non-privilegiato
USER comfyuser

EXPOSE ${COMFYUI_PORT}

CMD ["sh", "-c", "cd /app/ComfyUI && python3 main.py --listen 0.0.0.0 --port ${COMFYUI_PORT}"]
