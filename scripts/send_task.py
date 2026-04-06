#!/usr/bin/env python3
"""
Send a task to the AI agent via Redis queue.

Usage:
    ./send_task.py --project PROJECT_NAME --instruction "Your instruction here"
    ./send_task.py --project my-app --instruction "Add a README file"
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

import redis


def load_install_config() -> dict:
    values = {}
    config_path = Path(__file__).resolve().parent.parent / "install.conf"

    if not config_path.exists():
        return values

    for raw_line in config_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("'\"")

    return values


INSTALL_CONFIG = load_install_config()
AI_USER = INSTALL_CONFIG.get("AI_USER", "aiuser")
INSTALL_DEST_DIR = INSTALL_CONFIG.get("INSTALL_DEST_DIR", "local-ai-agent")
INSTALL_ROOT = f"/home/{AI_USER}/{INSTALL_DEST_DIR}"
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
CONFIG_PATH = os.getenv("CONFIG_REPO_PATH", f"{INSTALL_ROOT}/settings/repos")
DOCKER_DIR = f"{INSTALL_ROOT}/docker"


def load_repositories():
    """Load repository config to validate project name."""
    config_file = os.path.join(CONFIG_PATH, "repos.json")
    try:
        with open(config_file, "r", encoding="utf-8") as f:
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

    repos = load_repositories()
    if args.project not in repos:
        print(f"Error: Project '{args.project}' not found in configuration")
        print(f"Available projects: {', '.join(repos.keys()) if repos else 'none'}")
        sys.exit(1)

    try:
        r = redis.Redis.from_url(REDIS_URL, decode_responses=True)
        r.ping()
    except Exception:
        print(f"Error: Cannot connect to Redis at {REDIS_URL}")
        print(f"Make sure Redis is running: cd {DOCKER_DIR} && docker compose up -d redis")
        sys.exit(1)

    task = {
        "project": args.project,
        "instruction": args.instruction,
    }

    task_json = json.dumps(task)
    r.lpush("task:queue", task_json)

    print("Task sent to agent")
    print(f"  Project: {args.project}")
    print(f"  Instruction: {args.instruction[:80]}...")

    if args.wait:
        print("\nWaiting for result...")

        pubsub = r.pubsub()
        pubsub.subscribe("task:results", "task:errors")

        start_time = time.time()
        timeout = 60

        for message in pubsub.listen():
            if message["type"] == "message":
                result = json.loads(message["data"])
                if result.get("project") == args.project:
                    if result.get("success"):
                        print("\nTask completed successfully")
                        if result.get("pr_url"):
                            print(f"  Pull Request: {result['pr_url']}")
                    else:
                        print(f"\nTask failed: {result.get('error', 'Unknown error')}")
                    break

            if time.time() - start_time > timeout:
                print("\nTimeout waiting for result (60 seconds)")
                print("  Check agent logs: docker logs langgraph-agent")
                break

        pubsub.close()

    print("\nTo check status:")
    print("  docker logs langgraph-agent --tail 50")


if __name__ == "__main__":
    main()
