#!/bin/bash
# ============================================================================
# Gemini Agent Workspace — First-Time Setup
# ============================================================================
# Run this once to build and start your agent's environment.
# After this, the container runs in the background permanently.
# ============================================================================

set -e  # Exit immediately if any command fails

echo ""
echo "🤖 Gemini Agent Workspace — Setup"
echo "=================================="
echo ""

# --- Step 1: Build the Docker image ---
echo "📦 Step 1/4: Building the Docker image..."
echo "   (This downloads Ubuntu, Python, Node, Dart, Gemini CLI, etc.)"
echo "   (First build takes 3-10 minutes depending on your internet.)"
echo ""
docker compose build
echo ""
echo "   ✅ Image built successfully."
echo ""

# --- Step 2: Start the container ---
echo "🚀 Step 2/4: Starting the container..."
docker compose up -d   # -d = "detached" (runs in background)
echo "   ✅ Container is running."
echo ""

# --- Step 3: Copy workspace template files ---
echo "📄 Step 3/4: Setting up workspace files..."

# Copy soul.md template
docker cp ./workspace-template/soul.md gemini-agent:/home/agent/workspace/soul.md
docker cp ./workspace-template/GEMINI.md gemini-agent:/home/agent/workspace/GEMINI.md
docker cp ./workspace-template/memory.md gemini-agent:/home/agent/workspace/memory.md

# Fix ownership (files copied via docker cp are owned by root)
docker exec gemini-agent sudo chown -R agent:agent /home/agent/workspace

echo "   ✅ Workspace files ready."
echo ""

# --- Step 4: Install shell aliases ---
echo "🔧 Step 4/4: Installing shell aliases..."

ALIAS_SOURCE="source \"$(pwd)/agent-aliases.sh\""
SHELL_RC=""

# Detect which shell config file to use
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Only add if not already present
    if ! grep -q "agent-aliases.sh" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Gemini Agent Workspace aliases" >> "$SHELL_RC"
        echo "$ALIAS_SOURCE" >> "$SHELL_RC"
        echo "   ✅ Aliases added to $SHELL_RC"
        echo "   Run: source $SHELL_RC  (or open a new terminal)"
    else
        echo "   ✅ Aliases already installed in $SHELL_RC"
    fi
else
    echo "   ⚠️  Could not detect shell config file."
    echo "   Add this line manually to your shell profile:"
    echo "   $ALIAS_SOURCE"
fi

echo ""
echo "=================================="
echo "✅ Setup complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Load aliases:    source $SHELL_RC"
echo "  2. Enter the agent: agent-shell"
echo "  3. Authenticate:    gemini  (then follow the browser login prompt)"
echo "  4. Start working!   The agent will read soul.md and GEMINI.md"
echo ""
echo "Useful commands:"
echo "  agent-shell          — Open a shell inside the agent container"
echo "  agent-send <file>    — Copy a file into the agent's workspace"
echo "  agent-get <file>     — Copy a file from the agent's workspace"
echo "  agent-run \"prompt\"   — Run a one-off Gemini command"
echo "  agent-status         — Check if the container is running"
echo "  agent-stop           — Stop the container"
echo "  agent-start          — Start the container again"
echo ""
