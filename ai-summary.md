# AI Summary

## Project Purpose

This repository builds and installs a local AI agent environment inside a Linux VM.

The system is meant to:

- run local LLMs through Ollama
- accept user requests through a web UI, REST API, and CLI
- process coding tasks against configured Git repositories
- create branches and pull requests instead of changing production code directly
- run mostly inside Docker, with a dedicated Linux user and a controlled workspace

The installation target is typically:

- `/home/aiuser/local-ai-agent`

## High-Level Architecture

### Main Runtime Components

The running stack is Docker-based and currently includes:

1. `ollama`
2. `redis`
3. `langgraph-agent`
4. `api-gateway`

### Component Responsibilities

#### Ollama

- serves installed local AI models over HTTP
- default internal URL: `http://ollama:11434`
- keeps downloaded model data in a persistent Docker volume

#### Redis

- stores the task queue
- stores durable task status records
- acts as lightweight shared state for queued tasks

#### LangGraph Agent

- consumes tasks from Redis queue `task:queue`
- loads allowed repositories from `settings/repos/repos.json`
- clones or updates the target repository in `/workspace`
- creates a branch based on the instruction
- sends repository context to an Ollama model
- writes file changes returned by the model
- commits and pushes changes
- creates a GitHub pull request
- updates task status in Redis

#### API Gateway

- serves the web UI
- exposes REST API endpoints
- lets the browser queue repository tasks
- lets the browser talk directly to Ollama in chat mode
- reads the shared activity log
- exposes installed Ollama models to the UI

## Main User Flows

### Queued Repository Task Flow

1. User submits a task from:
   - CLI
   - web form
   - REST API
2. API or CLI creates a `task_id`
3. Task is stored in Redis as a durable record
4. Task JSON is pushed to Redis queue `task:queue`
5. Agent pops the task
6. Agent updates status from `queued` to `running`
7. Agent processes repository changes
8. Agent updates status to `completed` or `failed`
9. UI and API can poll task state by `task_id`

### Direct Chat Flow

1. User opens `/chat`
2. API loads installed models from Ollama
3. User selects a model and sends a message
4. Browser calls `POST /api/chat`
5. API sends a non-streaming chat request to Ollama
6. API returns the assistant reply to the browser

This chat flow is separate from the queued repository agent flow.

## Current Web UI

### Pages

#### `/`

Main dashboard.

Purpose:

- submit queued repository tasks
- choose a configured project
- choose a model override from installed models
- see recent tasks

Template file:

- `www/index.html`

#### `/chat`

Direct browser chat with a selected installed model.

Purpose:

- choose one installed Ollama model
- send synchronous chat requests
- keep short in-browser conversation history

Template file:

- `www/chat.html`

#### `/tasks/<task_id>`

Task detail page.

Purpose:

- show task status
- show selected model
- show timestamps
- show PR URL and error state

Template file:

- `www/task_detail.html`

#### `/status`

System status page.

Purpose:

- show shared activity log in a scrolling panel
- clear the shared log
- show installed Ollama models

Template file:

- `www/status.html`

### Shared CSS

Common web styling is in:

- `www/common.css`

## Current REST API

### Health and Discovery

- `GET /health`
- `GET /api/projects`
- `GET /api/models`

### Queued Tasks

- `POST /api/tasks`
- `GET /api/tasks`
- `GET /api/tasks/{task_id}`

### Direct Chat

- `POST /api/chat`

## Task Data Model

### Task Record Fields

Each task record stored in Redis includes:

- `task_id`
- `project`
- `instruction`
- `model`
- `submitted_by`
- `status`
- `created_at`
- `updated_at`
- `pr_url`
- `error`
- `success`

### Status Values

- `queued`
- `running`
- `completed`
- `failed`

### Redis Keys and Structures

- queue list: `task:queue`
- recent task index list: `tasks:index`
- per-task hash: `task:<task_id>`

## Logging

### Shared Activity Log

There is one shared log file:

- `logs/activity.log`

It is intended to contain:

- setup output
- API log messages
- CLI task submission messages
- agent runtime messages

### Logging Behavior

- setup appends to the activity log from the beginning of `setup/setup.sh`
- the API writes to the same log
- the CLI sender writes to the same log
- the agent writes to the same log
- `/status` reads and clears this file

## Repository Configuration

### Allowed Repositories

The list of repositories the agent may work on is stored in:

- `settings/repos/repos.json`

Each repository entry contains:

- `name`
- `url`
- `branch`

This file is used by:

- the agent
- the CLI
- the API

## Installation Model

### Host Assumptions

The project is designed for:

- Ubuntu Server inside a VM
- Docker installed on the VM
- a dedicated Linux user named `aiuser`

### Install Phases

The main setup flow is in:

- `setup/setup.sh`

It orchestrates:

1. system dependencies
2. Docker installation
3. Python dependencies
4. dedicated user creation
5. secrets configuration
6. directory creation and file copy
7. Docker image build and container startup
8. Ollama model pull

### Bootstrap Script

The bootstrap entrypoint is:

- `setup/install-from-web.sh`

It:

- clones the repo into `temp-web-install`
- removes stale temp clones automatically
- detects an existing installation
- asks before running install cleanup
- preserves Docker volumes during reinstall by default
- reruns the main setup

## Startup and Reboot Behavior

### After Setup

If setup completes successfully:

- the services are already started
- no reboot is required before first use

### After Reboot

Services auto-start because:

- Docker is enabled as a system service
- containers use `restart: unless-stopped`

This startup is handled by Docker under the system service context, not by an interactive `aiuser` login shell.

## Docker Details

### Compose File

Main runtime definition:

- `setup/docker/docker-compose.yml`

### Important Mounted Paths

#### Agent

- `../workspace:/workspace`
- `../logs:/app/logs`
- `../settings/repos:/settings/repos:ro`
- `../.env:/app/.env:ro`
- `../agent:/app/agent`
- `../shared:/app/shared`

#### API

- `../settings/repos:/settings/repos:ro`
- `../api:/app/api`
- `../shared:/app/shared`
- `../www:/app/www`
- `../logs:/app/logs`

### Shared Image

The agent and API currently share the same Docker build:

- `setup/docker/Dockerfile.agent`

## Key Source Folders

### `agent/`

Core worker code.

Main files:

- `langgraph_agent.py`
- `repo_manager.py`

### `api/`

FastAPI gateway.

Main files:

- `main.py`
- `services/redis_client.py`
- `services/repositories.py`
- `services/tasks.py`
- `services/ollama.py`

### `shared/`

Shared Python helpers reused across agent, CLI, and API.

Main files:

- `config.py`
- `logging_utils.py`
- `repos.py`
- `tasks.py`

### `run/`

Daily runtime tools.

Main file:

- `send_task.py`

### `setup/`

Installer, doctor, reset, and Docker setup assets.

### `www/`

Rendered browser pages and shared stylesheet.

## Security and Operational Model

### Security Choices

- no authentication is currently required because the web UI is intended for local LAN use
- future authentication is planned, and the API boundary was chosen to support that
- GitHub credentials are stored in `.env`, not in Git
- the workspace is isolated from the host by the VM and Docker layers

### Human Review Model

When repository modifications are requested, the intended flow is:

- agent creates a branch
- agent pushes the branch
- agent opens a pull request
- human reviews before merge

## Current Limitations

### Chat

- chat history is only kept in the browser for the current page session
- chat uses direct Ollama calls, not the full agent workflow
- chat is currently non-streaming

### Agent Generation

- repository edits are generated by prompting the model with selected file contents
- file writes are based on model-returned JSON
- this is functional but still fairly simple and not yet a full tool-using agent system

### Web UI

- the UI is server-rendered HTML, not a JS frontend framework
- it is intentionally simple and LAN-oriented

## If Rebuilding the Project from This Summary

### Minimum Rebuild Targets

To reproduce the current project, rebuild these pieces:

1. a Docker Compose stack with `ollama`, `redis`, `langgraph-agent`, and `api-gateway`
2. a Redis-backed task queue and task status store
3. a LangGraph worker that:
   - validates project names
   - clones configured repos
   - asks Ollama for file updates
   - commits, pushes, and opens PRs
4. a FastAPI app that:
   - lists projects
   - lists installed Ollama models
   - queues repository tasks
   - shows task status
   - serves `/`, `/chat`, `/tasks/<task_id>`, and `/status`
   - proxies direct chat requests to Ollama
5. a shared log file shown in `/status`
6. installer scripts that:
   - create the install root
   - create `aiuser`
   - configure Docker
   - start the stack
   - pull a default Ollama model

### Minimal Data Dependencies

You also need:

- `install.conf`
- `.env`
- `settings/repos/repos.json`

### Minimal Runtime Assumptions

- Ubuntu-like host
- Docker Engine + Docker Compose plugin
- outbound access to GitHub and Ollama model downloads during setup
- LAN browser access to port `8000`

## Documentation Pattern

The repository now follows a folder-local documentation pattern:

- most project folders contain their own `README.md`
- the root `README.md` gives the big picture
- folder READMEs explain what each folder and file is for
