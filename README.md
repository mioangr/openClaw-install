# local-ai-install

Instructions and scripts to install a **local AI and AI agent environment**.

This repository provides a **reproducible, script-based  (to the extent possible) setup** to deploy an isolated AI and AI agent inside a virtual machine, with controlled access to system resources and GitHub.

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


---


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

# Selected components and reasoning for their choice.
The following components (AI and helper components) are needed to build such a system:
ToDo: reseach to build the list of components.

---

### Key Design Points:
- **Isolation**: VM → Docker → dedicated user (`aiuser`)
- **Communication**: Only outbound to GitHub API (restricted, authenticated)
- **Safety**: PR workflow ensures human review gate
- **Extensibility**: Multi-channel input pattern supports future additions (email, webhooks)
- **Auditability**: All actions logged for review and debugging

---

# 🧱 Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│ Windows/Linux Host │ │ │ │ ┌──────────────────────────────────────────────────────┐ │ │ │ VMware VM (Ubuntu Server) │ │ │ │ │ │ │ │ ┌─────────────────────────────��──────────────────┐ │ │ │ │ │ Docker Environment │ │ │ │ │ │ │ │ │ │ │ │ ┌──────────────┐ ┌──────────────────────┐ │ │ │ │ │ │ │ DeepSeek │ │ OpenClaw Agent │ │ │ │ │ │ │ │ (Local LLM) │◄─┤ • GitHub integration │ │ │ │ │ │ │ │ │ │ • Code generation │ │ │ │ │ │ │ └──────────────┘ │ • Command execution │ │ │ │ │ │ │ │ • PR workflows │ │ │ │ │ │ │ └──────────────────────┘ │ │ │ │ │ │ │ │ │ │ │ │ │ aiuser (Linux) │ │ │ │ │ │ │ ┌──────────────────────────┼──────────────┐ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ Working Directory │ │ │ │ │ │ │ │ │ • Git repos (cloned) │ │ │ │ │ │ │ │ │ • Generated code/files │ │ │ │ │ │ │ │ │ • Logs & audit trail │ │ │ │ │ │ │ │ │ ▼ │ │ │ │ │ │ │ │ ┌──────────────────┐ │ │ │ │ │ │ │ │ │ GitHub APIs │ │ │ │ │ │ │ │ │ │ • Clone repos │ │ │ │ │ │ │ │ │ │ • Create PRs │ │ │ │ │ │ │ │ │ │ • Manage branches │ │ │ │ │ │ │ │ └──────────────────┘ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ └──────────────────────────────────────────┘ │ │ │ │ │ │ │ │ │ │ │ │ Isolated Filesystem (restricted access) │ │ │ │ │ │ │ │ │ │ │ └────────────────────────────────────────────────┘ │ │ │ │ │ │ │ │ Network: │ │ │ │ • Outbound: GitHub API (HTTPS) │ │ │ │ • Email receiver (optional) │ │ │ │ • No inbound access to host │ │ │ │ │ │ │ └──────────────────────────────────────────────────────┘ │ │ │ └─────────────────────────────────────────────────────────────┘

Input Channels (Multi-channel): ├─ GitHub Issues/Discussions (polling or webhooks) ├─ REST API endpoints (local or exposed) ├─ Email (forwarded to agent) └─ Web UI dashboard (future)

Output: └─ GitHub PRs (human reviews before merge) └─ Audit logs & execution records
```

# 🧱 Architecture Overview
ToDo: update
```
Windows Host  
   └── VMware VM (Ubuntu Server)  
         ├── Docker  
         │     └── AI agent (e.g. OpenClaw)  
         ├── Limited filesystem access  
         └── GitHub bot account (restricted)

To define: where the other local AI component will reside? In separate dockers? Which AI components are needed? Which AI agent should be used? 
```

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

Download and execute:

```bash
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/openClaw-install/main/setup_openclaw.sh
chmod +x setup_openclaw.sh
sudo ./setup_openclaw.sh
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
cd ~/openclaw
docker compose up -d
```

---

# 🔑 Secrets Management

Secrets are stored locally in:

```
/home/aiuser/openclaw/.env
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
