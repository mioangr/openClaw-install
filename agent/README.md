# AI Agent - LangGraph Implementation

This folder contains the core AI agent code that processes tasks and interacts with GitHub.

## Files

| File | Purpose |
|------|---------|
| `langgraph_agent.py` | Main agent loop - listens to Redis queue, processes instructions |
| `repo_manager.py` | Utilities for loading repository configurations |

## How the Agent Works

1. **Startup**: Agent connects to Redis and waits for tasks on queue `task:queue`
2. **Task Reception**: Task format: `{"project": "my-project", "instruction": "Add error handling"}`
3. **Lookup**: Reads `settings/repos/repos.json` to find repository URL for the project
4. **Execution Flow**:
   - Clone repository (or update if exists)
   - Create new branch (`ai-<instruction-slug>`)
   - Generate code changes using DeepSeek LLM
   - Apply changes to files
   - Commit and push to GitHub
   - Create Pull Request
   - Publish result to `task:results` channel
5. **Logging**: All actions logged to `/app/logs/agent.log`

## Adding Custom Tools

The agent uses LangGraph, which makes it easy to add new capabilities. To add a tool:

1. Define a new function in `langgraph_agent.py`
2. Add it to the workflow graph
3. Update the prompt to instruct the LLM when to use it

Example: Adding a tool to run tests
```python
def run_tests(state: AgentState) -> AgentState:
    subprocess.run(["pytest", state["local_path"]], check=True)
    return state
```

### Configuration
Environment variables (set in docker-compose.yml or .env):
- OLLAMA_URL: LLM server endpoint
- REDIS_URL: Redis connection string
- GITHUB_TOKEN: GitHub personal access token
- WORKSPACE: Temporary directory for repo clones
- CONFIG_REPO_PATH: Path to repos.json

### Manual Testing
Run the agent outside Docker for testing:

```bash
cd /home/aiuser/local-ai-agent/agent
export GITHUB_TOKEN=your_token
python langgraph_agent.py
```

Then in another terminal:

```bash
redis-cli LPUSH task:queue '{"project": "example-project", "instruction": "Add a README"}'
```
