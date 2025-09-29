# ArmyknifeLabs Platform Installer - Development Container
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up working directory
WORKDIR /workspace

# Install base dependencies and tools
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    pkg-config \
    # Version control
    git \
    git-lfs \
    # Network tools
    curl \
    wget \
    netcat \
    iputils-ping \
    dnsutils \
    net-tools \
    # Text processing
    jq \
    yq \
    sed \
    awk \
    grep \
    # Archive tools
    zip \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    # System tools
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    # Shell and terminal
    bash \
    zsh \
    tmux \
    vim \
    nano \
    # Python (for testing Python module)
    python3 \
    python3-pip \
    python3-venv \
    # Node.js setup
    nodejs \
    npm \
    # Additional utilities
    htop \
    tree \
    ncdu \
    file \
    less \
    man-db \
    && rm -rf /var/lib/apt/lists/*

# Install gum for terminal UI (required by the installer)
RUN echo "deb [trusted=yes] https://repo.charm.sh/apt/ /" | tee /etc/apt/sources.list.d/charm.list && \
    apt-get update && \
    apt-get install -y gum && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user 'developer'
RUN groupadd -g 1000 developer && \
    useradd -m -u 1000 -g developer -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up the workspace permissions
RUN chown -R developer:developer /workspace

# Switch to developer user
USER developer

# Set up shell environment
RUN echo "export PATH=/home/developer/.local/bin:\$PATH" >> ~/.bashrc && \
    echo "export ARMYKNIFE_DIR=/home/developer/.armyknife" >> ~/.bashrc && \
    mkdir -p /home/developer/.armyknife/{bin,lib,config,logs,cache}

# Copy the project files (will be overridden by volume mount in devcontainer.json)
COPY --chown=developer:developer . /workspace/

# Set the default shell to bash
SHELL ["/bin/bash", "-c"]

# Default command
CMD ["/bin/bash"]