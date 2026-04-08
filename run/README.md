# Runtime Scripts

Daily-use scripts for interacting with the AI agent system after setup is complete.

## Scripts Overview

| Script | Purpose | Example |
|--------|---------|---------|
| `send_task.py` | Send a task to the agent | `./send_task.py --project my-app --instruction "Add logging"` |

## Usage

`send_task.py` connects to Redis to communicate with the agent. Make sure Redis is running before using it:
```bash
cd /home/aiuser/local-ai-agent/docker && docker compose ps redis
```

Setup and recovery scripts now live under `setup/` on the VM host:
```bash
cd /home/aiuser/local-ai-agent/setup
./doctor.sh
```

### Sending a Task
```bash
./send_task.py --project my-web-app --instruction "Add error handling to the login function"
```

The script will:
- Load repository configuration
- Validate the project exists
- Push the task to Redis queue
- Wait for result (or return immediately with task ID)

### Managing Repositories
Edit the repository list manually in:
```bash
/home/aiuser/local-ai-agent/settings/repos/repos.json
```

### Environment
These scripts expect:
- Redis running on localhost:6379 (default)
- Configuration at /home/aiuser/local-ai-agent/settings/repos/repos.json
- You can override with environment variables:

```bash
export REDIS_URL=redis://localhost:6379
export CONFIG_REPO_PATH=/custom/path
```
