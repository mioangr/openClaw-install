
#### `scripts/send_task.py`

```python
#!/usr/bin/env python3
"""
Send a task to the AI agent via Redis queue.

Usage:
    ./send_task.py --project PROJECT_NAME --instruction "Your instruction here"
    ./send_task.py --project my-app --instruction "Add a README file"
"""

import argparse
import json
import sys
import os
import redis
import time

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
CONFIG_PATH = os.getenv("CONFIG_REPO_PATH", "/home/aiuser/settings/repos")

def load_repositories():
    """Load repository config to validate project name"""
    config_file = os.path.join(CONFIG_PATH, "repos.json")
    try:
        with open(config_file, 'r') as f:
            data = json.load(f)
            return {repo["name"]: repo for repo in data.get("repos", [])}
    except FileNotFoundError:
        print(f"Warning: Config file not found at {config_file}")
        return {}

def main():
    parser = argparse.ArgumentParser(description="Send task to AI agent")
    parser.add_argument("--project", required=True, help="Project name (as configured in repos.json)")
    parser.add_argument("--instruction", required=True, help="Instruction for the agent")
    parser.add_argument("--wait", action="store_true", help="Wait for result (max 60 seconds)")
    
    args = parser.parse_args()
    
    # Validate project exists
    repos = load_repositories()
    if args.project not in repos:
        print(f"Error: Project '{args.project}' not found in configuration")
        print(f"Available projects: {', '.join(repos.keys()) if repos else 'none'}")
        sys.exit(1)
    
    # Connect to Redis
    try:
        r = redis.Redis.from_url(REDIS_URL, decode_responses=True)
        r.ping()
    except Exception as e:
        print(f"Error: Cannot connect to Redis at {REDIS_URL}")
        print(f"Make sure Redis is running: cd /home/aiuser/docker && docker compose up -d redis")
        sys.exit(1)
    
    # Prepare task
    task = {
        "project": args.project,
        "instruction": args.instruction
    }
    
    # Push to queue
    task_json = json.dumps(task)
    r.lpush("task:queue", task_json)
    
    print(f"✓ Task sent to agent")
    print(f"  Project: {args.project}")
    print(f"  Instruction: {args.instruction[:80]}...")
    
    if args.wait:
        print("\nWaiting for result...")
        
        # Subscribe to results channel
        pubsub = r.pubsub()
        pubsub.subscribe("task:results", "task:errors")
        
        start_time = time.time()
        timeout = 60
        
        for message in pubsub.listen():
            if message["type"] == "message":
                result = json.loads(message["data"])
                if result.get("project") == args.project:
                    if result.get("success"):
                        print(f"\n✓ Task completed successfully!")
                        if result.get("pr_url"):
                            print(f"  Pull Request: {result['pr_url']}")
                    else:
                        print(f"\n✗ Task failed: {result.get('error', 'Unknown error')}")
                    break
            
            if time.time() - start_time > timeout:
                print("\n⚠ Timeout waiting for result (60 seconds)")
                print("  Check agent logs: docker logs langgraph-agent")
                break
        
        pubsub.close()
    
    print("\nTo check status:")
    print(f"  docker logs langgraph-agent --tail 50")

if __name__ == "__main__":
    main()