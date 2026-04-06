# local-ai-install

Instructions and scripts to install a **local AI and AI agent environment**.

This repository provides a **reproducible, script-based (to the extent possible) setup** to deploy an isolated AI and AI agent inside a virtual machine, with controlled access to system resources and GitHub.

---
# 🎯 Purpose
To have an AI and AI agent that can collaborate with me on a public or private repository.  
It should be able to write software or complete other writing tasks (e.g. a book) according to the provided instructions.  
It should have the capability to build a software from the specifications alone. Or write a book using the instructions on the content and the description of the audience.
It should be able to accept instructions via email or a chat window.  

**A secure, self-hosted AI collaborator** that works alongside you on code and writing projects.
Send instructions via **email or chat**, and your AI agent will:
- 💻 Build software from specifications alone and update the specifications to reflect the code updates
- 📚 Write books based on content guidelines and audience description
- 🔄 Collaborate on public and private repositories
- 📝 Accept multi-channel instructions (email, REST API, web UI)
- 🔐 Keep all work private and local (using DeepSeek)
- ✅ Submit work as PRs for your review before merging


# 🔐 Security Model

This setup is designed with **practical isolation**:

### Isolation Layers

* VM isolates from host OS
* Docker isolates the agent inside the VM
* Dedicated Linux user (`aiuser`) isolates execution context

### Key Security Decisions

* ❌ No direct access to host filesystem
* ❌ No secrets stored in GitHub
* ✅ Secrets stored locally in `.env`
* ⚠️ Docker group = root-equivalent (acceptable in VM)

---

### Key Design Points:
- **Isolation**: VM → Docker → dedicated user (`aiuser`)
- **Communication**: Only outbound to GitHub API (restricted, authenticated)
- **Safety**: PR workflow ensures human review gate
- **Extensibility**: Multi-channel input pattern supports future additions (email, webhooks)
- **Auditability**: All actions logged for review and debugging

---

# Selected components and reasoning for their choice.
To achieve the stated goals, the following components are required:

## Infrastructure & Orchestration
- **Ubuntu VM**: Host isolation layer
- **Dedicated Linux user (`aiuser`)**: Process-level execution isolation
- **Docker & Docker Compose**: Containerization for reproducibility and isolation
- **`.env` secrets management**: Secure credential storage without GitHub exposure

## AI & LLM Layer
- **DeepSeek** (via Ollama in a separate container): Runs locally, can build software from specifications and generate written content
- **LangGraph** (Python framework): Orchestrates interactions with GitHub, filesystem, and command execution. More flexible and easier to customise than black‑box agents.

## Integration & Communication Layer
- **GitHub API & Git**: For repository interaction, PR workflow, and code version control
- **Email integration** (optional but planned): For multi-channel instruction input
- **REST API** (FastAPI or similar): For webhook receivers and agent task triggering
- **Web UI** (optional): User-friendly dashboard for instructions and monitoring

## Security & Control Layer
- **Fine-grained GitHub tokens or SSH deploy keys**: Least-privilege repository access
- **PR workflow enforcement**: Human review gate before code merges
- **Execution safeguards** (planned): Command approval and filesystem restrictions
- **Audit logging**: Track agent actions for security review

## Reasoning
Each component directly supports one or more goals:
- Local LLM → Privacy requirement
- LangGraph → Full control over automation of software building and writing tasks
- GitHub integration → Collaboration workflow
- Docker + VM → Security model requirement
- Multi-channel input → Flexibility of instruction delivery
- PR workflow → Quality control and human oversight


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
│ │ │ - /home/aiuser/workspace (ephemeral clones)         │    │  │
│ │ │ - /home/aiuser/.env (secrets, read-only)            │    │  │
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
## Overview of folders and scripts 

```
local-ai-agent/
├── setup.sh # ONE-TIME SETUP: Run this first
├── setup/ai-agent/ # All installation scripts
├── settings/repos/ # Repository configurations
├── setup/docker/ # Docker and container files
├── agent/ # AI agent code
├── scripts/ # Utility scripts
└── logs/ # Runtime logs
```

## Folder structure and contents

```
local-ai-agent/
├── README.md                          # Main project documentation (updated)
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
│   ├── 08-pull-model.sh               # Pull DeepSeek model
│   └── common.sh                      # Common functions (error handling)
├── settings/repos/                      # Repository configurations
│   ├── README.md                      # Documentation for repo configs
│   └── repos.json                     # List of managed repositories
├── setup/docker/                      # Docker-related files
│   ├── README.md                      # Docker setup documentation
│   ├── docker-compose.yml             # Main compose file
│   ├── Dockerfile.agent               # Agent container build
│   └── requirements.txt               # Python dependencies
├── agent/                             # Agent code
│   ├── README.md                      # Agent documentation
│   ├── langgraph_agent.py             # Main agent script
│   └── repo_manager.py                # Repository management utilities
├── scripts/                            # Helper scripts
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
         "branch": "main",
         "description": "Web application project"
       },
       {
         "name": "api-service", 
         "url": "https://github.com/username/api",
         "branch": "main",
         "description": "Backend API service"
       }
     ]
   }

2. Send commands with project name:

   ```bash
   ./scripts/send_task.py --project my-web-app --instruction "Add error handling to login function"

3. Agent automatically:

- Looks up repository URL from config
- Clones the specific project
-  Makes changes
- Creates PR

## Deployment

Run the deployment from your **main Linux user account**. The setup scripts handle the process of automatically creating a specific, dedicated `aiuser` account that will be used by the AI components.

You can create a subfolder (e.g., `setup`) in your home directory, clone the repository into it, and run the script from there.

**Option 1: Single-command install via URL**
```bash
curl -s https://raw.githubusercontent.com/mioangr/local-ai-agent/main/setup/install-from-web.sh | bash
```

**Option 2: Manual clone and install**
```bash
git clone https://github.com/mioangr/local-ai-agent.git setup
cd setup
chmod +x setup/setup.sh
sudo ./setup/setup.sh
```

## Component Placement & Responsibilities

| Component          | Location               | Purpose                                                            |
|--------------------|------------------------|------------------------------------------------------------------------|
| **Agent** (LangGraph) | Docker container       | Orchestrates tasks: clones repos, runs LLM queries, executes commands, creates PRs. |
| **LLM** (DeepSeek via Ollama) | Separate Docker container | Serves model locally over HTTP. No internet needed after download.      |
| **API Gateway**      | Separate container (FastAPI) | Receives instructions from email (via webhook), chat, or REST. Queues tasks for agent. |
| **Redis / Volume**   | Docker volume          | Stores conversation memory, task queues, audit logs.     |
| **Workspace**        | Host bind mount (`/home/aiuser/workspace`) | Ephemeral clones of repos; cleared after each run or PR |
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

The gateway writes a task to Redis queue; the agent polls or listens, executes, and pushes results back (e.g., PR link, written chapters).

## Missing Pieces (to be added in future)

- Command approval layer (human-in-the-loop for dangerous commands)
- Resource limits (CPU/RAM for agent & LLM containers)
- Automatic cleanup of workspace after PR merge
  
---

# ⚙️ Setup Instructions

## 1. Prerequisites

* Windows host
* VMware Workstation or VMware Fusion
* Ubuntu Server installed inside VM
* Internet access inside VM
* Linux security hardening and extra packages were installed with the script [linux-initial-config.sh](linux-initial-config.sh)
* A "Golden image" is created for this state of linux so it can be reused in the next steps (installation of Docker and AI components)

---



## 2. Run Setup Script

Make sure to run this step from your **main Linux user account** (the script will automatically create the dedicated `aiuser` account for the AI running context).

**Method A: Automated URL Installation**
Download and execute directly into a new `setup/` subfolder:
```bash
curl -s https://raw.githubusercontent.com/mioangr/local-ai-agent/main/setup/install-from-web.sh | bash
```

**Method B: Manual Installation**
Clone into a `setup/` folder and execute:
```bash
git clone https://github.com/mioangr/local-ai-agent.git setup
cd setup
chmod +x setup/setup.sh
sudo ./setup/setup.sh
```


## 3. What the Script Does (Bootstrap)

> **Bootstrap** = Initial automated setup of a fresh system.

The script is **idempotent** (safe to re-run) and performs:

* system update
* installs required packages
* installs Docker (if not already installed)
* creates `aiuser`
* adds user to Docker group
* creates working directory
* prompts for secrets and stores them in `.env`
* creates a starter `docker-compose.yml`

---

## 4. After Setup

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
cd ~/local-ai-agent
docker compose up -d
```

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

# 🧪 Reset / Reproducibility

To reset environment:

```bash
sudo ./reset_openclaw.sh
```

This script:

* removes Docker containers/images
* deletes `aiuser`
* deletes OpenClaw files
* optionally removes Docker

---

# 📦 Design Principles

* reproducibility (script-based setup)
* minimal assumptions
* explicit configuration
* safe defaults
* easy teardown/reset
* portable across machines

---

# 🚧 Current Status (IMPORTANT CONTEXT)

This project is **in active development**.

## What is already implemented

* VM-based architecture
* Docker installation automation
* AI user creation
* environment setup script (idempotent)
* reset script
* `.env` secrets handling

## What is NOT yet implemented

* actual OpenClaw container integration
* GitHub authentication automation
* command safety controls
* execution sandboxing policies

---

# 🔮 Next Steps

Planned improvements:

### 🔐 Security

* restrict OpenClaw command execution
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

### 🧠 OpenClaw Integration

* install and configure OpenClaw inside container
* connect to LLM (local or API)
* logging and monitoring

### 🔁 Dev Workflow

* ephemeral repo clones
* auto-cleanup after runs
* audit logs of agent actions



---


# 🧠 Context for Future Development (AI Memory)

This section summarizes the intent so development can continue without re-explaining everything:

* Target user is a developer building an AI-assisted coding workflow
* System must be:

  * secure enough for experimentation
  * easy to reset
  * portable between machines
* OpenClaw is expected to:

  * interact with GitHub
  * generate and modify code
  * run commands (with safeguards)
* Current phase:

  * infrastructure setup (not agent logic yet)
* Next phase:

  * controlled agent capabilities + GitHub workflow

---

# ⚠️ Disclaimer

This project allows execution of automated commands.

* Use only inside isolated environments (VM recommended)
* Do not expose sensitive data
* Always review agent-generated code

---

# 📌 Notes

* This repository intentionally avoids complex DevOps tools (e.g. Ansible) for simplicity
* Designed for gradual evolution toward a more advanced system

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
