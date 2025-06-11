# Claude Code Docker Environment
# Based on official Claude Code devcontainer patterns

FROM node:20-bullseye

# Install system dependencies (minimal set)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y

# Install Claude Code globally as root (before creating user)
RUN npm install -g @anthropic-ai/claude-code@latest

# Create non-root user
RUN useradd -m -s /bin/bash claude && \
    echo 'claude ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to claude user and setup directories
USER claude
WORKDIR /home/claude

# Create necessary directories with proper ownership
RUN mkdir -p /home/claude/.claude \
    /home/claude/.config \
    /home/claude/workspace

# Set working directory to workspace (where projects are mounted)
WORKDIR /workspace

# Default command
CMD ["bash"]
