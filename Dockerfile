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
    COMFYUI_PORT=${COMFYUI_PORT} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    UV_CACHE_DIR=/app/.cache/uv

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

# Crea SOLO le directory cache PRIMA di installare ComfyUI
RUN mkdir -p /app/.cache /app/.local && \
    chown -R comfyuser:comfyuser /app/.cache /app/.local

# Assicurati che pip sia disponibile e aggiornato
RUN pip install --upgrade pip setuptools wheel

# Installa PyTorch con CUDA
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129

# Installa ComfyUI in directory temporanea e poi sposta
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI-temp && \
    cd /app/ComfyUI-temp && pip install -r requirements.txt && \
    mv /app/ComfyUI-temp /app/ComfyUI

# Installa TUTTE le dipendenze di ComfyUI Manager
RUN pip install toml GitPython requests packaging opencv-python pillow numpy scipy websockets aiohttp psutil

# Installa ComfyUI Manager nel percorso CORRETTO
RUN cd /app/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip install -r requirements.txt

# Installa uv esplicitamente per evitare errori
RUN pip install uv

# Crea SOLO la configurazione di sicurezza per ComfyUI Manager
RUN mkdir -p /app/ComfyUI/user/default/ComfyUI-Manager && \
    echo -e "[manager]\nsecurity_level = weak" > /app/ComfyUI/user/default/ComfyUI-Manager/config.ini

# Imposta i permessi FINALI su tutto
RUN chown -R comfyuser:comfyuser /app/ComfyUI

# Crea link simbolici per i comandi Python
RUN ln -sf /opt/python3.12/bin/pip /usr/local/bin/pip && \
    ln -sf /opt/python3.12/bin/python3 /usr/local/bin/python3 && \
    ln -sf /opt/python3.12/bin/python3 /usr/local/bin/python

# Esegui come utente non-privilegiato
USER comfyuser

EXPOSE ${COMFYUI_PORT}

CMD ["sh", "-c", "cd /app/ComfyUI && python3 main.py --listen 0.0.0.0 --port ${COMFYUI_PORT}"]
