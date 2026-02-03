FROM lscr.io/linuxserver/webtop:debian-xfce

# Switch to root to handle installations
USER root
ARG DEBIAN_FRONTEND=noninteractive

# Update and install basic transport tools
RUN apt-get update && apt-get install -y \
    curl \
    gpg \
    apt-transport-https \
    ca-certificates \
    ubuntu-drivers-common   
RUN ubuntu-drivers autoinstall

# Add NVIDIA package repository
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    sudo dpkg -i cuda-keyring_1.1-1_all.deb && \
    sudo apt-get update

# Install only runtime libraries (example for CUDA 12.3)
RUN sudo apt install -y cuda-cudart-12-3 libcublas-12-3 libcusparse-12-3
ENV LD_LIBRARY_PATH=/usr/local/cuda-12.3/lib64:$LD_LIBRARY_PATH   


# Add the Antigravity repository to sources.list.d
RUN mkdir -p /etc/apt/keyrings
# Add Google's official GPG key and the Antigravity repo
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list

# Update the package cache
RUN apt update

# Install the antigravity package
RUN apt install antigravity

# Disable Antigravity telemetry by creating user settings file
RUN mkdir -p /root/.config/Antigravity/User
COPY antigravity-settings.json /root/.config/Antigravity/User/settings.json

# Disable VSCode telemetry by creating a similar user settings file.
RUN mkdir -p /root/.config/Code/User
COPY vscode-settings.json /root/.config/Code/User/settings.json   


# Install GitHub SpecKit
RUN npm install -g @github/speckit && \
pip3 install --no-cache-dir gemini-cli --break-system-packages

# Install gemini-cli
RUN pip3 install gemini-cli


# Clean up to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the environment to allow Fuse (needed for AppImages/containers)
ENV APPIMAGE_EXTRACT_AND_RUN=1