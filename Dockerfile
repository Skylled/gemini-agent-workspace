# ============================================================================
# Gemini Agent Workspace — Dockerfile
# ============================================================================
# This file is a "recipe" that tells Docker how to build your agent's
# environment. Each line builds on the last, like layers of a cake.
# You only need to rebuild when you change THIS file (not your workspace data).
# ============================================================================

# Start from Ubuntu 24.04 — a clean, minimal Linux installation.
# "bookworm" and "noble" are codenames; this is a well-supported base.
FROM ubuntu:24.04

# Prevent interactive prompts during package installation.
# Without this, some packages try to ask you questions mid-build and hang.
ENV DEBIAN_FRONTEND=noninteractive

# ---- System packages ----
# Update the package list, then install core tools:
#   - curl, wget: download things from the internet
#   - git: version control
#   - unzip, zip: archive handling
#   - build-essential: C/C++ compiler tools (needed by some packages)
#   - sudo: lets us run commands as root when needed
#   - jq: parse JSON in the terminal (handy for scripting)
#   - ripgrep (rg): fast code search
#   - tree: visualize directory structures
#   - apt-transport-https: needed for some package repositories
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    build-essential \
    sudo \
    jq \
    ripgrep \
    tree \
    apt-transport-https \
    ca-certificates \
    gnupg \
    nano \
    && rm -rf /var/lib/apt/lists/*
    # ↑ Clean up the package cache to keep the image small

# ---- Python ----
# Install Python 3, pip (package manager), and venv (virtual environments)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# ---- Node.js 22 (LTS) ----
# Gemini CLI requires Node.js. We install v22 from NodeSource.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---- Dart SDK (stable) ----
# Standalone Dart — no Flutter, just the core SDK for CLI/server work.
# We download the SDK directly because the apt repo only has amd64 packages,
# and Apple Silicon Macs run arm64 Docker containers natively.
# This detects the architecture at build time so it works on both.
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then DART_ARCH="arm64"; \
    else DART_ARCH="x64"; fi && \
    curl -fsSL "https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-${DART_ARCH}-release.zip" \
    -o /tmp/dart-sdk.zip && \
    unzip -q /tmp/dart-sdk.zip -d /opt && \
    rm /tmp/dart-sdk.zip

# Add Dart to PATH
ENV PATH="/opt/dart-sdk/bin:$PATH"

# ---- Gemini CLI ----
# Install globally via npm. The `-g` flag makes it available everywhere.
RUN npm install -g @google/gemini-cli

# ---- Enable 256 colors ----
# Gemini CLI complains about not having 256 colors. This fixes that error.
ENV TERM=xterm-256color

# ---- Create a non-root user ----
# Running as root inside a container is bad practice.
# We create a user called "agent" with sudo access (just in case).
RUN useradd -m -s /bin/bash agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the agent user for everything that follows
USER agent
WORKDIR /home/agent

# ---- Workspace directory ----
# This is where the persistent volume will be mounted.
# Think of it as the agent's "home base" that survives restarts.
RUN mkdir -p /home/agent/workspace

# ---- Gemini config directory ----
# This is where Gemini CLI stores auth tokens and settings.
# We also make this persistent so you don't have to re-login every time.
RUN mkdir -p /home/agent/.gemini

# ---- Default shell setup ----
# Add some nice defaults to the shell
RUN echo 'export PATH="/opt/dart-sdk/bin:$HOME/.pub-cache/bin:$PATH"' >> ~/.bashrc \
    && echo 'cd /home/agent/workspace' >> ~/.bashrc \
    && echo 'echo "🤖 Gemini Agent Workspace ready."' >> ~/.bashrc \
    && echo 'echo "   Run: gemini  — to start an interactive session"' >> ~/.bashrc \
    && echo 'echo "   Workspace: /home/agent/workspace"' >> ~/.bashrc

# Keep the container running indefinitely.
# "tail -f /dev/null" is a common trick — it does nothing but prevents
# the container from exiting, so you can exec into it whenever you want.
CMD ["tail", "-f", "/dev/null"]
