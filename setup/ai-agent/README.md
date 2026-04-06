# AI Agent Setup Scripts

This folder contains all scripts required for the one-time installation of the AI agent environment.

Shared installer settings live in the repo-root `install.conf` file.

## Scripts Overview

| Script | Purpose | When to run |
|--------|---------|-------------|
| `common.sh` | Shared functions and error handling | Sourced by other scripts |
| `01-system-deps.sh` | Installs git, curl, build tools | Once, before anything else |
| `02-docker.sh` | Installs Docker Engine and Compose | After system deps |
| `03-python-deps.sh` | Installs Python and pip packages | After Docker |
| `04-create-user.sh` | Creates `aiuser` with proper permissions | After Python |
| `05-secrets.sh` | Prompts for and stores GitHub token | After user creation |
| `06-directories.sh` | Creates project folder structure | After secrets |
| `07-docker-compose.sh` | Builds and starts Docker containers | After directories |
| `08-pull-model.sh` | Downloads DeepSeek model via Ollama | Last step |

## Error Handling

Each script uses the `die()` function from `common.sh` to display friendly error messages and exit on failure. If a script fails, it will show:
- What went wrong
- Possible causes
- How to fix it

## Rerunning Scripts

Most scripts are idempotent (safe to rerun). If you need to restart from a specific step:
```bash
  bash setup/ai-agent/03-python-deps.sh  # Run only Python setup
```

## Manual Intervention
Some steps may require manual input:
- 05-secrets.sh will prompt for your GitHub token
- 08-pull-model.sh shows download progress
