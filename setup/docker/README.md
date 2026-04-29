# Docker Configuration

This folder contains all Docker-related files for containerizing the AI agent.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Orchestrates Ollama, Redis, the agent, and the API gateway |
| `Dockerfile.agent` | Builds the shared Python image used by the agent and API |
| `requirements.txt` | Python dependencies for the agent and API |
| `README.md` | Folder-local documentation for the Docker assets |

## Container Overview

### 1. Ollama (LLM Server)
- **Image**: `ollama/ollama:latest`
- **Port**: 11434 (internal)
- **Volume**: `ollama-data` (persists downloaded models)
- **Models**: Installed after setup from the web UI at `/add-remove-components`

### 2. LangGraph Agent
- **Build**: Custom from `Dockerfile.agent`
- **Dependencies**: Python 3.11, LangGraph, GitHub CLI
- **Volume**: `./workspace` (ephemeral repo clones)
- **Network**: Talks to Ollama and Redis

### 3. Redis
- **Image**: `redis:7-alpine`
- **Purpose**: Task queue and conversation memory
- **Volume**: `redis-data` (persists queues)

### 4. API Gateway
- **Build**: Reuses `Dockerfile.agent`
- **Port**: 8000 (LAN access)
- **Purpose**: Provides the web UI and REST API
- **Auth**: Anonymous today via `AUTH_MODE=anonymous`, designed so auth can be added later

## Network

All containers communicate on `ai-network` (bridge). The API gateway exposes port 8000 to the host for local-LAN access. Ollama still exposes 11434 for debugging.

## Resource Limits

Default limits in `docker-compose.yml`:
- Ollama: 8GB RAM
- Agent: 2GB RAM, 1 CPU
- Redis: 512MB RAM (implied)
- API Gateway: 512MB RAM, 0.5 CPU

Adjust based on your VM's resources.

## Commands

```bash
cd /home/aiuser/local-ai-agent/docker

# Start all containers
docker compose up -d

# Stop all containers
docker compose down

# View logs
docker compose logs -f

# Rebuild after code changes
docker compose build --no-cache
docker compose up -d

# Restart a specific container
docker compose restart langgraph-agent

# Open the API logs
docker compose logs -f api-gateway
```

## Troubleshooting

### Container won't start
```bash
docker compose logs <container-name>
```

### Ollama can't find model
```bash
docker exec ollama ollama list
```
Open `http://<vm-ip>:8000/add-remove-components` to install a model.

### Permission denied on workspace
```bash
sudo chown -R 1000:1000 ./workspace  # User 1000 is inside container
```
