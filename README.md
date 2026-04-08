# local-ai-install

Instructions and scripts to install a **local AI and AI agent environment**.

This repository provides a **reproducible, script-based (to the extent possible) setup** to deploy an isolated AI and AI agent in a virtual machine, with controlled access to system resources and GitHub repositories.

The end result is an AI and AI agent system that can collaborate with you on a public or private repository, to build software or complete other tasks.

---
# Features
 
- It should be able to write software or complete other writing tasks (e.g. a book) according to the provided instructions.  
- It should have the capability to build a software from the specifications alone. And also update the specifications and documentation to reflect the code updates.
- It should be able to write a book using the instructions on the content and the description of the audience and thhe learning outcomes.
- It should be able to accept instructions via different channels (REST API, email, chat web UI, etc).  
- When the required action is to modify the files, it should submit work as GIT pull requests for a review by the user before merging.
- It should allow the user to select which model to use when sending a request.
- It should have a list of local (open) models to select for local installation during the setup.
- It should also have a list of cloud models (together with the user's credentials or API tokens).


# 🔐 Security Model

### Isolation Layers

* VM isolates from host OS
* Docker isolates the agent inside the VM
* Dedicated Linux user (`aiuser`) isolates execution context

### Key Security Decisions

* No direct access to host filesystem
* No secrets stored in GitHub
* Secrets stored locally in `.env`
* Docker group = root-equivalent (acceptable in VM)
* Communication: Only outbound to GitHub API (restricted, authenticated)
* Pull Request workflow ensures human review gate
* All actions logged for review and debugging
* Fine-grained GitHub tokens or SSH deploy keys**: Least-privilege repository access

---

# Selected components and reasoning for their choice.
To achieve the stated goals, the following components are required:

## AI & LLM Layer
- **DeepSeek** (via Ollama in a separate container): Runs locally, can build software from specifications and generate written content
- **LangGraph** (Python framework): Orchestrates interactions with GitHub, filesystem, and command execution. More flexible and easier to customise than black‑box agents.


# 🧱 Architecture Overview

## High-Level Diagram
```
┌─────────────────────────────────────────────────────────────────┐
│ Windows Host                                                    │
│ (VMware Workstation/Fusion)                                     │
│                                                                 │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │ Ubuntu Server VM (Golden Image)                            │  │
│ │                                                            │  │
│ │ ┌──────────────────────────────────────────────────────┐   │  │
│ │ │ Docker Engine                                        │   │  │
│ │ │                                                      │   │  │
│ │ │ ┌───────────────────┐      ┌────────────────────┐    │   │  │
│ │ │ │ Agent Container   │      │ LLM Container      │    │   │  │
│ │ │ │ (LangGraph)       │◄────►│ (Ollama + DeepSeek)|    │   │  │
│ │ │ │                   │ HTTP │                    │    │   │  │
│ │ │ │ - GitHub CLI/Git  │      │ - Model serving    │    │   │  │
│ │ │ │ - Command exec    │      │ - Quantized weights│    │   │  │
│ │ │ │ - File sandbox    │      └────────────────────┘    │   │  │
│ │ │ └─────────┬─────────┘                                │   │  │
│ │ │           │                                          │   │  │
│ │ │ ┌─────────▼─────────┐ ┌────────────────────┐         │   │  │
│ │ │ │ API Gateway       │ │ Redis/Volume       │         │   │  │
│ │ │ │ (FastAPI)         │ │ (state & logs)     │         │   │  │
│ │ │ └─────────┬─────────┘ └────────────────────┘         │   │  │
│ │ │           │                                          │   │  │
│ │ └───────────┼──────────────────────────────────────────┘   │  │
│ │             │                                              │  │
│ │ ┌───────────▼─────────────────────────────────────────┐    │  │
│ │ │ Host Volumes (bind mounts)                          │    │  │
│ │ │ - /home/aiuser/local-ai-agent/workspace             │    │  │
│ │ │ - /home/aiuser/local-ai-agent/.env                  │    │  │
│ │ └─────────────────────────────────────────────────────┘    │  │
│ │                                                            │  │
│ │ ┌─────────────────────────────────────────────────────┐    │  │
│ │ │ External Access (controlled)                        │    │  │
│ │ │ - Outbound HTTPS to GitHub API                      │    │  │
│ │ │ - Inbound from email (via SMTP relay or webhook)    │    │  │
│ │ │ - Inbound from chat (Matrix/Telegram webhook)       │    │  │
│ │ └─────────────────────────────────────────────────────┘    │  │
│ └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```


## Folder structure and contents

```
local-ai-agent/                        # Subfolder where everything is installed.
├── README.md                          # Main project documentation (updated)
├── install.conf                       # Shared install configuration
├── setup.sh                           # Umbrella setup script (run once)
├── setup/ai-agent/                    # All setup scripts
│   ├── README.md                      # Overview of setup scripts
│   ├── 01-system-deps.sh              # Install system dependencies
│   ├── 02-docker.sh                   # Install Docker
│   ├── 03-python-deps.sh              # Install Python & packages
│   ├── 04-create-user.sh              # Create aiuser
│   ├── 05-secrets.sh                  # Configure secrets
│   ├── 06-directories.sh              # Create directory structure
│   ├── 07-docker-compose.sh           # Setup Docker Compose
│   ├── 08-pull-model.sh               # Pull configured Ollama model
│   └── common.sh                      # Common functions (error handling)
├── setup/docker/                      # Docker-related files
│   ├── README.md                      # Docker setup documentation
│   ├── docker-compose.yml             # Main compose file
│   ├── Dockerfile.agent               # Agent container build
│   └── requirements.txt               # Python dependencies
├── settings/repos/                    # Repository configurations
│   ├── README.md                      # Documentation for repo configs
│   └── repos.json                     # List of managed repositories
├── agent/                             # Agent code
│   ├── README.md                      # Agent documentation
│   ├── langgraph_agent.py             # Main agent script
│   └── repo_manager.py                # Repository management utilities
├── scripts/                           # Helper scripts
│   ├── README.md                      # Scripts documentation
│   └── send_task.py                   # Send task to agent
└── logs/                              # Log files (created at runtime)
```

## How It Works With Multiple Projects

1. **Configure repositories** in `settings/repos/repos.json`:
   ```json
   {
     "repos": [
       {
         "name": "my-web-app",
         "url": "https://github.com/username/web-app",
         "branch": "main"
       },
       {
         "name": "api-service", 
         "url": "https://github.com/username/api",
         "branch": "main"
       }
     ]
   }

2. Send commands with project name:

   ```bash
   ./scripts/send_task.py --project my-web-app --instruction "Add error handling to login function"

3. Agent automatically:

- Looks up repository URL from config
- Clones the specific project
- Makes changes
- Responds with answer and possibly creates PR

## Deployment

## 0. Prerequisites

* Windows host
* VMware Workstation or VMware Fusion
* Ubuntu Server installed inside VM
* Internet access inside VM
* Linux security hardening and extra packages were installed with the script [linux-initial-config.sh](0-Prerequisites/linux-golden-image/linux-initial-config.sh)
* A "Golden image" is created for this state of linux so it can be reused in the next steps (installation of Docker and AI components)


## 1. Install
> **Bootstrap** = Initial automated setup of a fresh system.

**Single-command install via URL**
```bash
curl -s https://raw.githubusercontent.com/mioangr/local-ai-agent/main/setup/install-from-web.sh | bash
```

Run the deployment from your **main Linux user account**.  
It will create a temporary subfolder (e.g., `temp-web-install`) in your home directory, clone the repository into it, and run the setup.sh script from there.   

Most setup steps are safe to rerun, and the recovery scripts above can help if a previous install stopped halfway. The bootstrap performs:

* system update
* installs required packages
* installs Docker (if not already installed)
* creates `aiuser`
* adds user to Docker group
* creates working directory
* prompts for secrets and stores them in `.env`
* creates a starter `docker-compose.yml`

After setup completes and the system is running normally, that temporary install folder is safe to delete.  

## 3. After Setup

Switch to the AI user:

```bash
su - aiuser
```

Test Docker:

```bash
docker run hello-world
```

Start environment:

```bash
cd /home/aiuser/local-ai-agent/docker
docker compose up -d
```


**Other maintainance scripts**

| Script | Purpose | Usage |
|--------|---------|-------|
| `rm -rf temp-web-install` | remove temp installation folder |  |
| repos.json | Edit the list of repos | `sudo nano /home/aiuser/local-ai-agent/settings/repos/repos.json`  |
| `doctor.sh` | Inspect the installation and report what is missing or unhealthy | `cd /home/aiuser/local-ai-agent/scripts && ./doctor.sh` |
| `reset-runtime.sh` | Stop containers and clear transient runtime state so you can retry the Docker/runtime steps | `cd /home/aiuser/local-ai-agent/scripts && ./reset-runtime.sh` |
| `reset-install.sh` | Remove the installed project files, and optionally the dedicated user, before reinstalling | `cd /home/aiuser/local-ai-agent/scripts && ./reset-install.sh --remove-user` |
| reset install  | from the web |  |



## Component Placement & Responsibilities

| Component          | Location               | Purpose                                                            |
|--------------------|------------------------|------------------------------------------------------------------------|
| **Agent** (LangGraph) | Docker container       | Orchestrates tasks: clones repos, runs LLM queries, executes commands, creates PRs. |
| **LLM** (DeepSeek via Ollama) | Separate Docker container | Serves model locally over HTTP. No internet needed after download.      |
| **API Gateway**      | Separate container (FastAPI) | Receives instructions from email (via webhook), chat, or REST. Queues tasks for agent. |
| **Redis / Volume**   | Docker volume          | Stores conversation memory, task queues, audit logs.     |
| **Workspace**        | Host bind mount (`/home/aiuser/local-ai-agent/workspace`) | Ephemeral clones of repos; cleared after each run or PR |
| **Secrets**          | Host file `.env` (600 perms) | Injected as environment variables into agent container (read-only). |

## Network & Security Rules

- Agent container **can only**:
  - Talk to LLM container (internal Docker network)
  - Talk to GitHub API (outbound HTTPS)
  - Talk to API Gateway (if same network)
  - Read/write within `/workspace` bind mount
- Agent container **cannot**:
  - Access host network except for above
  - Modify its own environment or Docker socket (unless explicitly needed – not recommended)
- All inbound instructions (email/chat) land on the API Gateway, which validates a simple secret before forwarding to the agent.

## How Multi-Channel Instructions Flow

1. **Email** → (optional) Postfix relay + script → HTTP POST to API Gateway.
2. **Chat** → Matrix/Telegram bot → HTTP POST to API Gateway.
3. **REST** → Direct `curl` or webhook → API Gateway.

The gateway writes a task to Redis queue; the agent polls or listens, executes, and pushes results back (e.g., textual answer, PR link, written chapters).



---

# 🔑 Secrets Management

Secrets are stored locally in:

```
/home/aiuser/local-ai-agent/.env
```

### Example:

```
GITHUB_TOKEN=xxxxx
OPENAI_API_KEY=xxxxx
```

### Rules

* ❌ Never commit `.env` to GitHub
* ✅ File permissions are restricted (`chmod 600`)
* ✅ Script prompts user on first run

---

# 🤖 GitHub Integration Strategy

Planned approach:

* create dedicated GitHub bot account
* use:

  * fine-grained token OR
  * SSH deploy key

### Intended workflow:

* agent clones repo
* agent creates branch
* agent submits PR
* human reviews before merge

---

# 🔮 Next Steps

Planned improvements:

### 🔐 Security

* add approval layer before execution
* limit filesystem access further

### 🔑 GitHub Integration

* SSH key setup script
* fine-grained token handling
* automated PR workflow

### 🐳 Docker Improvements

* hardened container config
* resource limits (CPU/memory)
* network restrictions

---

# ⚠️ Disclaimer

This project allows execution of automated commands.

* Use only inside isolated environments (VM recommended)
* Do not expose sensitive data
* Always review agent-generated code


---

# ⚖️ Legal Disclaimer and No Warranty

This project is provided **“as is”**, without any warranties or guarantees of any kind, express or implied.

The author makes **no representations or warranties** regarding:

* the correctness, completeness, or reliability of the code
* the fitness of the software for any particular purpose
* the security or safety of the system when used

By using this repository, you acknowledge that:

* the project may be **incomplete, experimental, or contain errors**
* it may cause **data loss, system instability, or unintended behavior**
* it is your responsibility to **review, test, and validate** all code before use

## Limitation of Liability

In no event shall the author be held liable for any:

* direct or indirect damages
* loss of data or profits
* system failures or security incidents

arising from the use or misuse of this software.

## Use at Your Own Risk

You agree to use this project **entirely at your own risk**.

It is strongly recommended to:

* run this software only in **isolated environments (e.g. virtual machines)**
* avoid using it on systems containing sensitive or critical data

---

By using this repository, you agree to the terms stated above.
