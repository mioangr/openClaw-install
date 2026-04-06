# Docker Configuration

This folder contains all Docker-related files for containerizing the AI agent.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Orchestrates all three containers (Ollama, Agent, Redis) |
| `Dockerfile.agent` | Builds the LangGraph agent container |
| `requirements.txt` | Python dependencies for the agent |

## Container Overview

### 1. Ollama (LLM Server)
- **Image**: `ollama/ollama:latest`
- **Port**: 11434 (internal)
- **Volume**: `ollama-data` (persists downloaded models)
- **Model**: deepseek-coder:6.7b-instruct-q4_K_M (~4GB)

### 2. LangGraph Agent
- **Build**: Custom from `Dockerfile.agent`
- **Dependencies**: Python 3.11, LangGraph, GitHub CLI
- **Volume**: `./workspace` (ephemeral repo clones)
- **Network**: Talks to Ollama and Redis

### 3. Redis
- **Image**: `redis:7-alpine`
- **Purpose**: Task queue and conversation memory
- **Volume**: `redis-data` (persists queues)

## Network

All containers communicate on `ai-network` (bridge). No ports are exposed to the host by default (except Ollama on 11434 for debugging).

## Resource Limits

Default limits in `docker-compose.yml`:
- Ollama: 8GB RAM
- Agent: 2GB RAM, 1 CPU
- Redis: 512MB RAM (implied)

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
```

## Troubleshooting

### Container won't start
```bash
docker compose logs <container-name>
```

### Ollama can't find model
```bash
docker exec ollama ollama list
docker exec ollama ollama pull deepseek-coder:6.7b-instruct-q4_K_M
```

### Permission denied on workspace
```bash
sudo chown -R 1000:1000 ./workspace  # User 1000 is inside container
```
