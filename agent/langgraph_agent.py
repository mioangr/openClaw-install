#!/usr/bin/env python3
"""
================================================================================
LangGraph AI Agent - Main Script
================================================================================
Purpose: Listens for tasks from Redis queue and executes them using LangGraph
         workflow. Tasks include cloning repos, generating code changes via LLM,
         and creating GitHub Pull Requests.

Usage: 
    - Run standalone: python langgraph_agent.py
    - Run via Docker: docker compose up langgraph-agent

Task format (Redis list "task:queue"):
    {"project": "project-name", "instruction": "user instruction"}

Output:
    - Result published to Redis channel "task:results"
    - Errors published to Redis channel "task:errors"
    - Logs written to /app/logs/agent.log
================================================================================
"""

import os
import subprocess
import json
import logging
import sys
from pathlib import Path
from typing import TypedDict, Dict, Any
import redis
from github import Github, GithubException, Repository
from langchain_community.llms import Ollama
from langgraph.graph import StateGraph, END

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from shared.repos import get_repository_map
from shared.logging_utils import APP_LOG_FILE, ensure_log_dir
from shared.tasks import ERROR_CHANNEL, QUEUE_NAME, RESULT_CHANNEL, update_task

# =============================================================================
# Configuration (from environment variables)
# =============================================================================
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://ollama:11434")
MODEL_NAME = os.getenv("MODEL_NAME", "qwen2.5-coder:1.5b")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_USERNAME = os.getenv("GITHUB_USERNAME")
WORKSPACE = os.getenv("WORKSPACE", "/workspace")
CONFIG_REPO_PATH = os.getenv("CONFIG_REPO_PATH", "/settings/repos")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# Setup logging
ensure_log_dir()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(APP_LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Validate required environment variables
if not GITHUB_TOKEN:
    logger.error("GITHUB_TOKEN environment variable not set")
    sys.exit(1)

if not GITHUB_USERNAME:
    logger.warning("GITHUB_USERNAME not set - some GitHub operations may fail")

# =============================================================================
# Initialize connections
# =============================================================================
try:
    redis_client = redis.Redis.from_url(REDIS_URL, decode_responses=True)
    redis_client.ping()
    logger.info(f"Connected to Redis at {REDIS_URL}")
except Exception as e:
    logger.error(f"Failed to connect to Redis: {e}")
    sys.exit(1)

LLM_CACHE: Dict[str, Ollama] = {}


def get_llm(model_name: str) -> Ollama:
    if model_name in LLM_CACHE:
        return LLM_CACHE[model_name]

    llm = Ollama(model=model_name, base_url=OLLAMA_URL, temperature=0.2)
    llm.invoke("ping")
    LLM_CACHE[model_name] = llm
    return llm


try:
    get_llm(MODEL_NAME)
    logger.info(f"Connected to Ollama at {OLLAMA_URL} with default model {MODEL_NAME}")
except Exception as e:
    logger.error(f"Failed to connect to Ollama: {e}")
    sys.exit(1)

try:
    gh = Github(GITHUB_TOKEN)
    user = gh.get_user()
    logger.info(f"Authenticated to GitHub as {user.login}")
except Exception as e:
    logger.error(f"Failed to authenticate with GitHub: {e}")
    sys.exit(1)

REPOSITORIES = get_repository_map()
logger.info(f"Loaded {len(REPOSITORIES)} repositories from config")

# =============================================================================
# LangGraph State Definition
# =============================================================================
class AgentState(TypedDict):
    """State passed between graph nodes"""
    task_id: str                 # Queue task ID
    project: str                 # Project name (key in REPOSITORIES)
    instruction: str             # User instruction
    model_name: str              # Requested model or default
    repo_url: str                # Full GitHub URL
    repo_branch: str             # Target branch
    local_path: str              # Local clone path
    branch_name: str             # New branch name for changes
    changes_made: bool           # Whether any files were modified
    pr_url: str                  # Resulting PR URL
    error: str                   # Error message if any

# =============================================================================
# Graph Node Functions
# =============================================================================
def validate_project(state: AgentState) -> AgentState:
    """Check if the project exists in configuration"""
    project = state["project"]
    
    if project not in REPOSITORIES:
        state["error"] = f"Project '{project}' not found in configuration"
        logger.error(state["error"])
        return state
    
    repo_info = REPOSITORIES[project]
    state["repo_url"] = repo_info["url"]
    state["repo_branch"] = repo_info["branch"]
    logger.info(f"Validated project '{project}' -> {state['repo_url']}")
    
    return state

def clone_repository(state: AgentState) -> AgentState:
    """Clone or update the repository in workspace"""
    if state.get("error"):
        return state
    
    repo_url = state["repo_url"]
    repo_name = repo_url.rstrip("/").split("/")[-1].replace(".git", "")
    local_path = os.path.join(WORKSPACE, repo_name)
    state["local_path"] = local_path
    
    # Create workspace directory if it doesn't exist
    os.makedirs(WORKSPACE, exist_ok=True)
    
    # Authenticated URL for cloning
    auth_url = repo_url.replace("https://", f"https://{GITHUB_TOKEN}@")
    
    try:
        if os.path.exists(local_path):
            logger.info(f"Repository exists at {local_path}, pulling latest")
            subprocess.run(["git", "-C", local_path, "pull"], 
                          check=True, capture_output=True, text=True)
        else:
            logger.info(f"Cloning {repo_url} to {local_path}")
            subprocess.run(["git", "clone", auth_url, local_path], 
                          check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        state["error"] = f"Git operation failed: {e.stderr}"
        logger.error(state["error"])
    
    return state

def create_branch(state: AgentState) -> AgentState:
    """Create a new branch for the changes"""
    if state.get("error"):
        return state
    
    local_path = state["local_path"]
    # Create branch name from instruction (sanitize)
    instruction_slug = state["instruction"][:40].replace(" ", "-").replace("/", "-")
    branch_name = f"ai-{instruction_slug}"
    state["branch_name"] = branch_name
    
    try:
        # Check if branch already exists remotely
        subprocess.run(["git", "-C", local_path, "fetch", "origin"], 
                      check=True, capture_output=True)
        
        # Create and checkout new branch
        subprocess.run(["git", "-C", local_path, "checkout", "-b", branch_name], 
                      check=True, capture_output=True, text=True)
        logger.info(f"Created branch: {branch_name}")
    except subprocess.CalledProcessError as e:
        state["error"] = f"Branch creation failed: {e.stderr}"
        logger.error(state["error"])
    
    return state

def generate_changes(state: AgentState) -> AgentState:
    """Use LLM to generate code changes based on instruction"""
    if state.get("error"):
        return state
    
    local_path = state["local_path"]
    instruction = state["instruction"]
    model_name = state["model_name"]
    
    # Collect relevant files (limit to avoid token overflow)
    files_context = {}
    total_chars = 0
    MAX_CONTEXT_CHARS = 8000  # Adjust based on model context window
    
    for root, _, files in os.walk(local_path):
        # Skip .git directory
        if ".git" in root:
            continue
            
        for file in files:
            if file.endswith((".py", ".md", ".txt", ".json", ".yaml", ".yml", ".js", ".ts")):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, local_path)
                try:
                    with open(full_path, "r", encoding="utf-8") as f:
                        content = f.read()
                        # Truncate if too long
                        if len(content) > 2000:
                            content = content[:2000] + "\n... (truncated)"
                        
                        files_context[rel_path] = content
                        total_chars += len(content)
                        
                        if total_chars > MAX_CONTEXT_CHARS:
                            logger.warning(f"Context limit reached, stopping at {rel_path}")
                            break
                except Exception as e:
                    logger.warning(f"Could not read {rel_path}: {e}")
    
    # Build prompt for LLM
    prompt = f"""You are an AI assistant that modifies code in a GitHub repository.

INSTRUCTION: {instruction}

Current files in the repository (paths and content):
{json.dumps(files_context, indent=2)}

Based on the instruction, produce a JSON object where:
- Each key is a file path (relative to repository root)
- Each value is the NEW content for that file
- Only include files that need to be changed
- If no changes are needed, output an empty JSON object: {{}}

RULES:
1. Output ONLY valid JSON - no additional text before or after
2. Preserve existing code structure and formatting
3. Add comments where appropriate
4. Make minimal changes necessary

JSON output:"""

    try:
        logger.info(
            f"Sending prompt to Ollama model '{model_name}' "
            f"(instruction: {instruction[:50]}...)"
        )
        response = get_llm(model_name).invoke(prompt)
        
        # Parse JSON response
        # Remove any markdown code blocks if present
        response = response.strip()
        if response.startswith("```json"):
            response = response[7:]
        if response.startswith("```"):
            response = response[3:]
        if response.endswith("```"):
            response = response[:-3]
        response = response.strip()
        
        changes = json.loads(response)
        
        if not changes:
            logger.info("LLM determined no changes needed")
            state["changes_made"] = False
            return state
        
        # Apply changes to files
        for rel_path, new_content in changes.items():
            full_path = os.path.join(local_path, rel_path)
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            logger.info(f"Updated file: {rel_path}")
        
        state["changes_made"] = True
        
    except json.JSONDecodeError as e:
        logger.error(f"LLM returned invalid JSON: {response[:200]}")
        state["error"] = f"LLM response parsing failed: {e}"
    except Exception as e:
        logger.error(f"LLM invocation failed: {e}")
        state["error"] = str(e)
    
    return state

def commit_and_push(state: AgentState) -> AgentState:
    """Commit changes and push to remote"""
    if state.get("error") or not state.get("changes_made"):
        return state
    
    local_path = state["local_path"]
    branch = state["branch_name"]
    instruction = state["instruction"]
    
    try:
        # Add all changes
        subprocess.run(["git", "-C", local_path, "add", "."], 
                      check=True, capture_output=True, text=True)
        
        # Commit
        commit_msg = f"AI: {instruction[:80]}"
        subprocess.run(["git", "-C", local_path, "commit", "-m", commit_msg], 
                      check=True, capture_output=True, text=True)
        
        # Push to remote
        subprocess.run(["git", "-C", local_path, "push", "--set-upstream", "origin", branch], 
                      check=True, capture_output=True, text=True)
        
        logger.info(f"Pushed branch {branch} to remote")
    except subprocess.CalledProcessError as e:
        state["error"] = f"Commit/push failed: {e.stderr}"
        logger.error(state["error"])
    
    return state

def create_pull_request(state: AgentState) -> AgentState:
    """Create a Pull Request using GitHub API"""
    if state.get("error") or not state.get("changes_made"):
        return state
    
    local_path = state["local_path"]
    branch = state["branch_name"]
    instruction = state["instruction"]
    base_branch = state["repo_branch"]
    
    try:
        # Get repository from remote URL
        remote_url = subprocess.run(
            ["git", "-C", local_path, "config", "--get", "remote.origin.url"],
            capture_output=True, text=True, check=True
        ).stdout.strip()
        
        # Parse owner/repo from URL
        # Example: https://github.com/owner/repo.git
        parts = remote_url.replace(".git", "").split("/")
        repo_owner = parts[-2]
        repo_name = parts[-1]
        
        repo = gh.get_repo(f"{repo_owner}/{repo_name}")
        
        pr = repo.create_pull(
            title=f"AI: {instruction[:80]}",
            body=f"## 🤖 AI-Generated Changes\n\n**Instruction:**\n{instruction}\n\n**Changes:**\n- Generated by LangGraph agent\n- Please review before merging\n\n*This PR was created automatically.*",
            head=branch,
            base=base_branch
        )
        
        state["pr_url"] = pr.html_url
        logger.info(f"Created PR: {pr.html_url}")
        
    except GithubException as e:
        state["error"] = f"GitHub API error: {e.data.get('message', str(e))}"
        logger.error(state["error"])
    except Exception as e:
        state["error"] = f"PR creation failed: {e}"
        logger.error(state["error"])
    
    return state

def cleanup(state: AgentState) -> AgentState:
    """Optional cleanup - currently disabled to preserve workspace for debugging"""
    # Uncomment to delete local clone after PR
    # import shutil
    # if os.path.exists(state["local_path"]):
    #     shutil.rmtree(state["local_path"], ignore_errors=True)
    #     logger.info(f"Cleaned up {state['local_path']}")
    return state

# =============================================================================
# Build LangGraph Workflow
# =============================================================================
def build_workflow() -> StateGraph:
    """Construct the LangGraph workflow"""
    workflow = StateGraph(AgentState)
    
    # Add nodes
    workflow.add_node("validate", validate_project)
    workflow.add_node("clone", clone_repository)
    workflow.add_node("branch", create_branch)
    workflow.add_node("generate", generate_changes)
    workflow.add_node("commit", commit_and_push)
    workflow.add_node("pr", create_pull_request)
    workflow.add_node("cleanup", cleanup)
    
    # Define edges (sequential flow)
    workflow.set_entry_point("validate")
    workflow.add_edge("validate", "clone")
    workflow.add_edge("clone", "branch")
    workflow.add_edge("branch", "generate")
    workflow.add_edge("generate", "commit")
    workflow.add_edge("commit", "pr")
    workflow.add_edge("pr", "cleanup")
    workflow.add_edge("cleanup", END)
    
    return workflow.compile()

# =============================================================================
# Task Processing Function
# =============================================================================
def process_task(task: Dict[str, Any]) -> Dict[str, Any]:
    """Execute a single task through the LangGraph workflow"""
    task_id = task["task_id"]
    project = task["project"]
    instruction = task["instruction"]
    model_name = task.get("model") or MODEL_NAME

    logger.info(f"Processing task: project='{project}', instruction='{instruction[:50]}...'")
    update_task(
        redis_client,
        task_id,
        status="running",
        model=model_name,
        error="",
        pr_url="",
        success="",
    )

    app = build_workflow()
    
    initial_state: AgentState = {
        "task_id": task_id,
        "project": project,
        "instruction": instruction,
        "model_name": model_name,
        "repo_url": "",
        "repo_branch": "",
        "local_path": "",
        "branch_name": "",
        "changes_made": False,
        "pr_url": "",
        "error": "",
    }
    
    try:
        final_state = app.invoke(initial_state)
        
        result = {
            "task_id": task_id,
            "project": project,
            "instruction": instruction,
            "model": model_name,
            "success": not bool(final_state.get("error")),
            "pr_url": final_state.get("pr_url", ""),
            "error": final_state.get("error", "")
        }

        update_task(
            redis_client,
            task_id,
            status="completed" if result["success"] else "failed",
            pr_url=result["pr_url"],
            error=result["error"],
            success=result["success"],
        )
        
        if result["success"]:
            logger.info(f"Task completed successfully. PR: {result['pr_url']}")
        else:
            logger.error(f"Task failed: {result['error']}")
        
        return result
        
    except Exception as e:
        logger.exception(f"Unexpected error processing task")
        result = {
            "task_id": task_id,
            "project": project,
            "instruction": instruction,
            "model": model_name,
            "success": False,
            "pr_url": "",
            "error": str(e)
        }
        update_task(
            redis_client,
            task_id,
            status="failed",
            pr_url="",
            error=result["error"],
            success=False,
        )
        return result

# =============================================================================
# Main Loop - Listen for Tasks
# =============================================================================
def main():
    """Main event loop - listens for tasks on Redis queue"""
    logger.info("=" * 60)
    logger.info("LangGraph AI Agent Started")
    logger.info(f"Redis: {REDIS_URL}")
    logger.info(f"LLM: {OLLAMA_URL} ({MODEL_NAME})")
    logger.info(f"GitHub: {GITHUB_USERNAME}")
    logger.info(f"Workspace: {WORKSPACE}")
    logger.info(f"Configured projects: {list(REPOSITORIES.keys())}")
    logger.info("=" * 60)
    logger.info("Listening for tasks on Redis list 'task:queue'...")
    
    while True:
        try:
            # Blocking pop from Redis list (timeout 10 seconds)
            result = redis_client.blpop(QUEUE_NAME, timeout=10)
            
            if result:
                _, task_json = result
                
                try:
                    task = json.loads(task_json)
                    task_id = task.get("task_id")
                    project = task.get("project")
                    instruction = task.get("instruction")
                    
                    if not task_id or not project or not instruction:
                        logger.error(
                            f"Invalid task format: missing task_id, project, or instruction - {task_json}"
                        )
                        continue
                    
                    # Process the task
                    task_result = process_task(task)
                    
                    # Publish result
                    if task_result["success"]:
                        redis_client.publish(RESULT_CHANNEL, json.dumps(task_result))
                    else:
                        redis_client.publish(ERROR_CHANNEL, json.dumps(task_result))
                        
                except json.JSONDecodeError:
                    logger.error(f"Invalid JSON task: {task_json}")
                except Exception as e:
                    logger.exception(f"Error processing task: {e}")
                    
        except KeyboardInterrupt:
            logger.info("Shutting down agent...")
            break
        except Exception as e:
            logger.exception(f"Unexpected error in main loop: {e}")
            continue

if __name__ == "__main__":
    main()
