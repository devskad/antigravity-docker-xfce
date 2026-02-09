FROM lscr.io/linuxserver/webtop:debian-xfce

# Default preinstalled webtop user is abc
ARG USER=abc

#=======================================================================
# Install linux packages, drivers & libraries
#-----------------------------------------------------------------------
# Switch to root to handle installations
ARG DEBIAN_FRONTEND=noninteractive

# Update and install basic transport tools
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    wget \
    bash \
    gpg \
    apt-transport-https \
    ca-certificates \
    git \
    nodejs \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# # Add NVIDIA package repository
# RUN mkdir -p /etc/apt/apt.conf.d && \
#     echo 'APT::Key::gpgvcommand "/usr/bin/gpgv";' > /etc/apt/apt.conf.d/99-force-gpgv && \
#     wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
#     dpkg -i cuda-keyring_1.1-1_all.deb && \
#     apt-get update

# # Install CUDA Toolkit
# RUN apt-get update && \
#     apt-get install -y openjdk-21-jre-headless openjdk-21-jre && \
#     apt-get install -y cuda-toolkit-13-1 && \
#     rm -rf /var/lib/apt/lists/* 

#=======================================================================
# Install apps
#-----------------------------------------------------------------------
# Install 'uv' and 'specify-cli'
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    /config/.local/bin/uv tool install specify-cli --from git+https://github.com/github/spec-kit.git && \
    /config/.local/bin/specify --help 
# Get uv into PATH
ENV PATH="/config/.local/bin:$PATH"

# Install 'gemini-cli'
RUN npm install -g @google/gemini-cli && \
    /usr/bin/gemini --help

# Install the antigravity package
#   Add the Antigravity repository to sources.list.d
RUN mkdir -p /etc/apt/keyrings
#   Add Google's official GPG key and the Antigravity repo
RUN curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list
# Install the antigravity package
RUN apt update && apt install antigravity \
    && rm -rf /var/lib/apt/lists/*

# Add speckit/Antigravity bridge global workspace rule
RUN mkdir -p /config/.gemini/antigravity/global_workflows
COPY speckit-implement.md /config/.gemini/antigravity/global_workflows/speckit-implement.md
# RUN chown -R abc /config/.gemini && chgrp -R abc /config/.gemini <--- don't do this as init.d will override it....
RUN mkdir -p /custom-cont-init.d
COPY set-gemini-perms.sh /custom-cont-init.d
RUN chmod +x /custom-cont-init.d/set-gemini-perms.sh

# Add additional setup scripts
COPY add-desktop-icons.sh /custom-cont-init.d
RUN chmod +x /custom-cont-init.d/add-desktop-icons.sh


#=======================================================================
# Do user-specific actions
#-----------------------------------------------------------------------
USER $USER
WORKDIR /home/$USER
# ENV HOME=/home/$USER <--- Don't try this or webtop will not start....

# Disable Antigravity telemetry by creating user settings file
RUN mkdir -p /home/$USER/.config/Antigravity/User
COPY antigravity-settings.json /home/$USER/.config/Antigravity/User/settings.json

# Disable VSCode telemetry by creating a similar user settings file.
RUN mkdir -p /home/$USER/.config/Code/User
COPY vscode-settings.json /home/$USER/.config/Code/User/settings.json

# Reconfigure our desktop
RUN mkdir -p /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml
COPY xfce4-panel.xml /config/xfce4-panel.xml
COPY xfce4-panel.xml /opt/defaults/xfce4-panel.xml

#=======================================================================
# Windup
#-----------------------------------------------------------------------
USER root
# Clean up to keep the image small
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
# Set the environment to allow Fuse (needed for AppImages/containers)
ENV APPIMAGE_EXTRACT_AND_RUN=1