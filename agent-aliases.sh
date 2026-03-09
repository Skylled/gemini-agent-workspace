#!/bin/bash
# ============================================================================
# Gemini Agent Workspace — Shell Aliases
# ============================================================================
# These aliases give you quick commands to interact with your agent.
# They're loaded automatically into your shell by setup.sh.
# ============================================================================

# Open an interactive shell inside the agent container.
# This is your main way to "enter" the agent's environment.
agent-shell() {
    docker exec -it gemini-agent bash -l
}

# Copy a file FROM your Mac INTO the agent's workspace.
# Usage: agent-send myfile.py
#        agent-send ./my-project  (works with directories too)
agent-send() {
    if [ -z "$1" ]; then
        echo "Usage: agent-send <file-or-directory>"
        echo "Copies a file from your Mac into the agent's workspace."
        return 1
    fi
    docker cp "$1" gemini-agent:/home/agent/workspace/
    # Fix ownership so the agent user can access it
    local basename=$(basename "$1")
    docker exec gemini-agent sudo chown -R agent:agent "/home/agent/workspace/$basename"
    echo "✅ Sent '$1' → agent:/home/agent/workspace/$basename"
}

# Copy a file FROM the agent's workspace TO your current directory.
# Usage: agent-get output.txt
#        agent-get my-project/result.json
agent-get() {
    if [ -z "$1" ]; then
        echo "Usage: agent-get <path-in-workspace>"
        echo "Copies a file from the agent's workspace to your current directory."
        return 1
    fi
    docker cp "gemini-agent:/home/agent/workspace/$1" .
    echo "✅ Got 'agent:workspace/$1' → ./$(basename "$1")"
}

# Run a one-off Gemini CLI command without entering the container.
# The agent processes your prompt and exits.
# Usage: agent-run "Summarize the files in this workspace"
#        agent-run "Write a Python script that sorts CSV files"
agent-run() {
    if [ -z "$1" ]; then
        echo "Usage: agent-run \"your prompt here\""
        echo "Runs a single Gemini command inside the agent container."
        return 1
    fi
    docker exec -it gemini-agent bash -lc "cd /home/agent/workspace && gemini -p \"$1\""
}

# Check if the agent container is running
agent-status() {
    if docker ps --format '{{.Names}}' | grep -q "^gemini-agent$"; then
        echo "✅ gemini-agent is running"
        docker ps --filter "name=gemini-agent" --format "   Uptime: {{.Status}}"
    else
        echo "❌ gemini-agent is not running"
        echo "   Start it with: agent-start"
    fi
}

# Stop the agent container (workspace data is preserved)
agent-stop() {
    docker compose -f "$(dirname "${BASH_SOURCE[0]}")/docker-compose.yml" down
    echo "🛑 Agent stopped. Your workspace data is safe."
}

# Start the agent container
agent-start() {
    docker compose -f "$(dirname "${BASH_SOURCE[0]}")/docker-compose.yml" up -d
    echo "🚀 Agent started."
}

# Rebuild the agent container (e.g., after editing the Dockerfile)
# Your workspace data is preserved — only the container environment changes.
agent-rebuild() {
    echo "🔧 Rebuilding agent container..."
    docker compose -f "$(dirname "${BASH_SOURCE[0]}")/docker-compose.yml" down
    docker compose -f "$(dirname "${BASH_SOURCE[0]}")/docker-compose.yml" build
    docker compose -f "$(dirname "${BASH_SOURCE[0]}")/docker-compose.yml" up -d
    echo "✅ Agent rebuilt and restarted. Workspace data preserved."
}
