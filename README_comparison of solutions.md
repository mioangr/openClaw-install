# local-ai-agent-env (Suggested Name)

Infrastructure as code for a **local AI agent environment** supporting code development, writing, and general-purpose tasks.

This repository provides a **reproducible, script-based setup** to deploy an isolated, multi-purpose AI agent inside a virtual machine, with controlled access to system resources, GitHub, and multi-channel instruction input (email, REST API, webhooks).

---

# 🏗️ Supported Agent Frameworks - Detailed Analysis

Based on 2024 research, here's the complete comparison:

## 1. **OpenClaw** (Recommended for this use case)

**What it is:**
- Open-source AI automation framework designed for event-driven workflows
- TypeScript-based; runs on Node.js
- Built specifically for agent orchestration with multiple input channels

**Capabilities:**
✅ Code generation (via connected LLM)  
✅ Writing tasks (via connected LLM)  
✅ GitHub integration (create PRs, issues)  
✅ Email integration (listen for instructions)  
✅ Webhook support (Discord, Slack, GitHub)  
✅ File system access (with restrictions)  
✅ Command execution (shell with safeguards)  
✅ Multi-agent coordination  
✅ Plugin/skill system (extensible)  
✅ Built-in logging and audit trails  

**System Requirements:**
- **Min RAM:** 2GB (agent framework alone)
- **Recommended RAM:** 4GB
- **Min Disk:** 10GB
- **CPU:** 2 cores minimum
- **Node.js:** 16+ required
- **LLM Backend:** Ollama or external API

**Pros:**
- Designed exactly for your use case
- Built-in email/webhook support
- Active development
- Good documentation for automation
- Plugin-based extensibility
- Event-driven (natural for responding to instructions)

**Cons:**
- Less mature than LangChain
- Smaller community
- TypeScript (if you prefer Python)
- Still in active development (APIs may change)

**Setup Time:** 2-3 weeks
**Complexity:** Medium

**References:**
- https://openclaw.im/
- https://github.com/openclaw/openclaw

---

## 2. **LangChain + FastAPI** (Most Flexible)

**What it is:**
- LangChain: Python framework for building LLM applications with tool chains
- FastAPI: Modern Python web framework for REST APIs
- Combined: Full-stack application framework with maximum customization

**Capabilities:**
✅ Code generation (via connected LLM)  
✅ Writing tasks (via connected LLM)  
✅ GitHub integration (via tools/plugins)  
✅ Email integration (custom IMAP listener required)  
✅ Webhook support (build custom endpoints)  
✅ File system access (with restrictions)  
✅ Command execution (with safeguards)  
✅ Complex reasoning chains  
✅ Multi-agent coordination (via tool chaining)  
✅ Extensive logging (via handlers)  

**System Requirements:**
- **Min RAM:** 2GB (framework alone)
- **Recommended RAM:** 4-6GB
- **Min Disk:** 10GB
- **CPU:** 2 cores minimum
- **Python:** 3.10+ required
- **LLM Backend:** Ollama, LM Studio, or API

**Pros:**
- Maximum flexibility (you build what you need)
- Mature ecosystem (3+ years development)
- Large community (many examples online)
- Python (more popular for data/ML work)
- Can integrate ANY library (no lock-in)
- Excellent documentation
- Production-ready
- Can use Pydantic for type safety

**Cons:**
- Higher learning curve
- You write more custom code
- Requires Python expertise
- More dependencies to manage
- More things that can go wrong
- Need to build email listener yourself

**Setup Time:** 3-4 weeks (more if you're new to Python)
**Complexity:** High

**References:**
- https://python.langchain.com/
- https://github.com/langchain-ai/langchain
- https://fastapi.tiangolo.com/

---

## 3. **CrewAI** (Modern Multi-Agent)

**What it is:**
- Python framework for building multi-agent systems
- Higher-level abstraction than LangChain
- Each agent has a role, goal, and set of tasks
- Built on top of LangChain

**Capabilities:**
✅ Code generation (via agent roles)  
✅ Writing tasks (via agent roles)  
✅ GitHub integration (custom tools needed)  
✅ Email integration (custom tools needed)  
✅ Webhook support (custom implementation)  
✅ File system access (with tool restrictions)  
✅ Command execution (via tools)  
✅ Multi-agent coordination (built-in orchestration)  
✅ Agent memory and context (across tasks)  
✅ Hierarchical agent management  

**System Requirements:**
- **Min RAM:** 2GB
- **Recommended RAM:** 4-6GB
- **Min Disk:** 10GB
- **CPU:** 2 cores minimum
- **Python:** 3.10+ required
- **LLM Backend:** Ollama, LM Studio, or API

**Pros:**
- Very intuitive agent definition (roles, goals, tasks)
- Excellent for multi-agent scenarios
- Built-in memory management
- Hierarchical execution (agents can spawn sub-agents)
- Cleaner abstraction than raw LangChain
- Good documentation with examples
- Active development

**Cons:**
- Newer than LangChain (less battle-tested)
- Still evolving API
- Less flexibility than LangChain (intentional trade-off)
- Requires LangChain knowledge to extend
- Email/webhook still custom

**Setup Time:** 2-3 weeks
**Complexity:** Medium-High

**References:**
- https://github.com/joaomdmoura/crewAI
- https://docs.crewai.com/

---

## 4. **Tabby** (Code-Specific Only - NOT Recommended)

**What it is:**
- Self-hosted code completion tool (like GitHub Copilot)
- Designed specifically for IDE integration
- Focuses on code generation, not general tasks

**Capabilities:**
✅ Code completion (excellent)  
✅ Code generation (good)  
✅ IDE integration (VS Code, JetBrains, Vim, Emacs)  
✅ Multiple language support  
❌ Writing tasks (not supported)  
❌ Email integration (not supported)  
❌ Webhook support (not supported)  
❌ General automation (not designed for it)  

**System Requirements:**
- **Min RAM:** 8GB (model inference)
- **Recommended RAM:** 12GB+
- **Min Disk:** 50GB (model + cache)
- **GPU:** 4GB+ VRAM (strongly recommended)
- **Model Size:** 7B-13B parameters

**Pros:**
- Excellent for code completion
- Easy to set up
- Multiple IDE support
- Very responsive

**Cons:**
- **NOT suitable for your multi-purpose needs**
- Code-only (no writing, no general tasks)
- Doesn't support email/webhook instructions
- Designed as IDE assistant, not automation engine
- Can't create PRs, can't interact with APIs

**Setup Time:** 1 week
**Complexity:** Low

**Verdict:** Skip Tabby for your use case. It's great for IDE assistance, but won't work for writing books or general automation.

---

## Framework Comparison Table

| Feature | OpenClaw | LangChain+FastAPI | CrewAI | Tabby |
|---------|----------|------------------|--------|-------|
| **Code Generation** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Writing Tasks** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **General Automation** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| **Email Input** | ✅ Built-in | ⚠️ Custom | ⚠️ Custom | ❌ |
| **Webhook Support** | ✅ Built-in | ✅ Easy | ⚠️ Custom | ❌ |
| **GitHub Integration** | ✅ Good | ✅ Excellent | ⚠️ Tools | ❌ |
| **Multi-Agent** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| **Setup Complexity** | Medium | High | Medium-High | Low |
| **Learning Curve** | Medium | High | Medium | Low |
| **Maturity** | Stable | Very Stable | Emerging | Stable |
| **Community Size** | Small-Med | Large | Growing | Medium |
| **Best For** | Multi-channel automation | Maximum flexibility | Multi-agent tasks | IDE coding only |

---

## Recommendation Matrix

**Use OpenClaw if:**
- You want email as primary instruction channel
- You prefer "batteries included" (plugins built-in)
- You want minimal custom code
- TypeScript is acceptable
- You need fast setup

**Use LangChain+FastAPI if:**
- You want maximum flexibility/customization
- You're comfortable writing Python code
- You need integration with many external systems
- You want the most mature, battle-tested option
- You're building something complex/unique

**Use CrewAI if:**
- You have multiple agents with different roles
- You want clean agent orchestration
- You like the "roles/goals/tasks" mental model
- You're building a collaborative system
- You want Python with structure

**Don't use Tabby if:**
- You need general-purpose automation
- You need to write books/content
- You need email-based instructions
- You need GitHub PR creation

---

# 💾 System Requirements - Complete

## Hardware (Host Computer)

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **RAM** | 16GB | 32GB+ | Host OS + VM both need RAM |
| **Disk Space** | 150GB total | 250GB+ | OS (20GB) + VM (100GB) + buffer |
| **CPU** | 4 cores | 8+ cores | Multi-core benefits LLM |
| **GPU** | Optional | 8GB+ VRAM | Dramatically speeds up LLM |
| **Internet** | 50 Mbps+ | 100 Mbps+ | For model downloads, GitHub API |

## Virtual Machine (Inside VMware)

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **RAM** | 12GB | 16GB+ | LLM is memory-hungry |
| **Disk** | 70GB | 100GB+ | Models (30-50GB) + OS + data |
| **CPU Cores** | 4 | 6-8 | More = faster inference |
| **GPU** | None | 4GB+ VRAM | GPU much faster than CPU |

## Per-Service Resource Allocation

| Service | Min RAM | Recommended | Min Disk | Notes |
|---------|---------|-------------|----------|-------|
| **Ollama** (LLM) | 8GB | 12GB+ | 50GB | Holds models; GPU accelerated |
| **OpenClaw** | 1GB | 2GB | 5GB | Orchestration engine |
| **LangChain+FastAPI** | 1.5GB | 3GB | 5GB | Agent + API server |
| **CrewAI** | 1GB | 2GB | 5GB | Multi-agent orchestration |
| **PostgreSQL** (optional) | 0.5GB | 1GB | 2GB | Task history/logging |
| **SQLite** (alternative) | Included | Included | 1GB | File-based DB |
| **Postfix Email** (optional) | 0.2GB | 0.5GB | 1GB | Local mail server |
| **System + Docker** | 1.5GB | 2GB | 10GB | OS + runtime overhead |
| **TOTAL** | **12GB** | **20GB+** | **70GB+** | — |

## Network Requirements

- **Internet Speed:** 50 Mbps minimum (for GitHub API calls, model downloads)
- **Latency:** <200ms recommended
- **VM Network:** Isolated/separate from host network (critical!)
- **Inbound Ports:** Only from host machine
  - 8000: REST API (if needed)
  - 11434: Ollama (internal only)
  - 5432: PostgreSQL (internal only)

---

# 🔐 Security Hardening (16-Point Guide)

[Full hardening guide from previous sections applies here]

---

# ⚙️ Updated Setup Instructions

[Your existing setup instructions, updated for multi-purpose framework]

---

# 📌 Next Steps

1. **Choose framework:** OpenClaw (recommended) or LangChain+FastAPI (flexible)
2. **Decide on input channels:** Email (easiest), REST API, Webhooks, or all three
3. **Select LLM model:** Mistral 7B (fast), Llama 2 7B (balanced), CodeLlama (code-focused)
4. **Plan hardening:** Implement at least network isolation + firewall
5. **Build custom tools:** GitHub, file I/O, email sending, command execution

---
