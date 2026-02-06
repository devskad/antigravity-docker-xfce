FROM lscr.io/linuxserver/webtop:debian-xfce

# Switch to root to handle installations
ARG DEBIAN_FRONTEND=noninteractive

# Update and install basic transport tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    bash \
    gpg \
    apt-transport-https \
    ca-certificates \
    git \
    nodejs \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ARG USER abc
# USER ${USER}

# Install 'uv' and 'specify-cli'
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    /config/.local/bin/uv tool install specify-cli --from git+https://github.com/github/spec-kit.git && \
    /config/.local/bin/specify --help 
# Get uv into PATH
ENV PATH="/config/.local/bin:$PATH"

# Install 'gemini-cli'
RUN npm install -g @google/gemini-cli && \
    /usr/bin/gemini --help

USER root

# # Add NVIDIA package repository
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
#     sudo dpkg -i cuda-keyring_1.1-1_all.deb && \
#     sudo apt-get update

# # Install only runtime libraries (example for CUDA 12.3)
# RUN sudo apt install -y cuda-cudart-12-3 libcublas-12-3 libcusparse-12-3 \
    # && rm -rf /var/lib/apt/lists/*
# ENV LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64:$LD_LIBRARY_PATH

# Add the Antigravity repository to sources.list.d
RUN mkdir -p /etc/apt/keyrings
# Add Google's official GPG key and the Antigravity repo
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list

# Install the antigravity package
RUN apt update && apt install antigravity \
    && rm -rf /var/lib/apt/lists/*


USER ${USER}

# Disable Antigravity telemetry by creating user settings file
RUN mkdir -p /home/${USER}.config/Antigravity/User
COPY antigravity-settings.json /home/${USER}.config/Antigravity/User/settings.json

# Disable VSCode telemetry by creating a similar user settings file.
RUN mkdir -p /home/${USER}.config/Code/User
COPY vscode-settings.json /home/${USER}.config/Code/User/settings.json

# Clean up to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the environment to allow Fuse (needed for AppImages/containers)
ENV APPIMAGE_EXTRACT_AND_RUN=1