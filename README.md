# Gemini Agent Workspace

A sandboxed, persistent workspace for running Gemini CLI as an autonomous agent — without giving it access to your actual system.

Vibe-coded by Claude Opus 4.6 with minor edits.

## What This Is

This sets up a **Docker container** (think: a lightweight virtual computer) that runs on your Mac. Inside it, Gemini CLI has its own Linux environment with Python, Dart, Node.js, and common dev tools. It has a permanent workspace that survives restarts, and a memory system so it can maintain context across sessions.

Your Mac's files are completely isolated from the agent. The only way files move between your Mac and the agent is through explicit commands you run.

## Prerequisites

1. **Docker Desktop for Mac**: Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/). Install it and make sure it's running (you'll see a whale icon in your menu bar).

2. **A Google account** with Gemini access (you already have this via your AI Pro subscription).

That's it. Everything else gets installed inside the container automatically.

## Quick Start

### 1. Build and start the agent

```bash
# Navigate to this directory
cd /path/to/gemini-agent-workspace

# Make the setup script executable (one time only)
chmod +x setup.sh

# Run setup
./setup.sh
```

This will:
- Build the Docker image (~3-10 min the first time)
- Start the container in the background
- Copy the workspace template files
- Install shell aliases for your terminal

### 2. Load the aliases

```bash
# If setup told you to source your shell config:
source ~/.zshrc    # (or ~/.bashrc)
```

### 3. Enter the agent and authenticate

```bash
# Open a shell inside the agent
agent-shell

# Start Gemini CLI — it will prompt you to log in
gemini
```

When Gemini starts for the first time, it will show three auth options. **Choose option 1: "Login with Google"**. It will display a URL — open that URL in your Mac's browser, sign in with your personal Google account (the one with your AI Pro subscription), and authorize the app. Once you see "Authentication successful" in your browser, return to the terminal.

**This login is cached.** You won't need to do it again unless the token expires (weeks/months). The cached credentials live in a persistent Docker volume, so they survive container restarts and rebuilds.

### 4. Start using the agent

Once authenticated, Gemini CLI drops you into an interactive session:

```
🤖 Gemini Agent Workspace ready.
$ gemini

> Summarize the projects in this workspace
> Create a new Dart CLI tool that converts CSV to JSON
> Review memory.md and tell me what we worked on last time
```

## Everyday Commands

Run these from your Mac's terminal (not inside the container):

| Command | What it does |
|---|---|
| `agent-shell` | Open an interactive shell in the agent container |
| `agent-send myfile.py` | Copy a file from your Mac into the agent's workspace |
| `agent-get result.txt` | Copy a file from the agent's workspace to your current directory |
| `agent-run "do something"` | Run a one-shot Gemini prompt without entering the container |
| `agent-status` | Check if the agent container is running |
| `agent-stop` | Stop the container (data is preserved) |
| `agent-start` | Start the container again |
| `agent-rebuild` | Rebuild after editing the Dockerfile (data is preserved) |

## File Transfer Examples

```bash
# Send a whole project directory to the agent
agent-send ~/Projects/my-dart-app

# Ask the agent to work on it
agent-run "Review the code in projects/my-dart-app and suggest improvements"

# Retrieve results
agent-get projects/my-dart-app/REVIEW.md
```

## How the Workspace Is Organized

Inside the container, everything lives under `/home/agent/workspace/`:

```
workspace/
├── soul.md       ← Agent's personality and behavior (you edit this)
├── GEMINI.md     ← Instructions Gemini reads automatically each session
├── memory.md     ← Session log maintained by the agent
└── projects/     ← Where the agent keeps its work
```

### soul.md
Defines the agent's name, personality, communication style, and boundaries. Open it and fill in the template to make the agent your own. This is read by Gemini at the start of each session.

### GEMINI.md
System-level instructions that Gemini CLI loads automatically (it looks for this file in the current directory). Tells the agent about its environment, tools, and how to use memory.md.

### memory.md
A running log of what happened in past sessions. The agent is instructed to append summaries here so it can maintain context. You can read and edit this yourself too.

## Customization

### Adding packages to the container

Edit the `Dockerfile`, then rebuild:

```bash
# Example: add ffmpeg to the container
# 1. Edit Dockerfile — add "ffmpeg" to the apt-get install list
# 2. Rebuild:
agent-rebuild
```

### Changing resource limits

Uncomment the `deploy.resources` section in `docker-compose.yml` to cap CPU and memory usage.

### Disabling internet access

Follow the comments in `docker-compose.yml` to enable the `no-internet` network. This gives you a fully air-gapped agent.

### Upgrading Gemini CLI

```bash
agent-shell
sudo npm update -g @google/gemini-cli
```

## Understanding Docker (Quick Primer)

Since you're new to Docker, here are the key concepts:

- **Image**: A snapshot/template of an environment (like a disk image). Built from the `Dockerfile`. You build it once and it doesn't change until you rebuild.

- **Container**: A running instance of an image. Like booting up from that disk image. You can stop, start, and delete containers without losing your data (because of volumes).

- **Volume**: Persistent storage that exists outside the container. Even if you delete and recreate the container, volumes keep your data. This project uses two volumes:
  - `agent-workspace` — your projects and files
  - `agent-gemini-config` — Gemini's auth tokens and settings

- **docker compose** — A tool that reads `docker-compose.yml` and manages your container, volumes, and networking with simple commands.

### Common Docker Commands (reference)

```bash
# See running containers
docker ps

# See all containers (including stopped)
docker ps -a

# See volumes
docker volume ls

# View container logs (if something goes wrong)
docker logs gemini-agent

# Nuclear option: remove everything and start fresh
# ⚠️ This DELETES your workspace data!
docker compose down -v    # -v removes volumes too
```

## Troubleshooting

### "Cannot connect to the Docker daemon"
Docker Desktop isn't running. Open it from your Applications folder and wait for the whale icon to appear in the menu bar.

### "Permission denied" on files sent to the agent
The setup script and `agent-send` command handle permissions automatically. If you still see issues, run inside the container:
```bash
sudo chown -R agent:agent /home/agent/workspace
```

### Gemini asks to re-authenticate
Auth tokens expire eventually. Just run `gemini` inside the container and follow the login flow again. The new token will be cached.

### Container exited unexpectedly
Check what happened:
```bash
docker logs gemini-agent
```
Then restart:
```bash
agent-start
```

## Adding a Shared Folder Later

If you decide you want the convenience of a shared folder instead of `docker cp`, add this line to `docker-compose.yml` under the `volumes` section of the `agent` service:

```yaml
volumes:
  - agent-workspace:/home/agent/workspace
  - agent-gemini-config:/home/agent/.gemini
  - ~/agent-shared:/home/agent/shared    # ← add this line
```

Then `agent-rebuild`. A `shared/` directory will appear inside the container at `/home/agent/shared`, and anything you put in `~/agent-shared` on your Mac will be visible to the agent (and vice versa). **Only put files here that you're okay with the agent modifying or deleting.**
