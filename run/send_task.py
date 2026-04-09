#!/usr/bin/env python3
"""
Send a task to the AI agent via Redis queue.

Usage:
    ./send_task.py --project PROJECT_NAME --instruction "Your instruction here"
    ./send_task.py --project my-app --instruction "Add a README file"
"""

import argparse
import os
import sys
import time
from pathlib import Path

import redis

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from shared.config import load_install_config
from shared.logging_utils import configure_file_logger
from shared.repos import get_repository_map
from shared.tasks import create_task_payload, get_task, submit_task


INSTALL_CONFIG = load_install_config()
AI_USER = INSTALL_CONFIG.get("AI_USER", "aiuser")
INSTALL_DEST_DIR = INSTALL_CONFIG.get("INSTALL_DEST_DIR", "local-ai-agent")
INSTALL_ROOT = f"/home/{AI_USER}/{INSTALL_DEST_DIR}"
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
CONFIG_PATH = os.getenv("CONFIG_REPO_PATH", f"{INSTALL_ROOT}/settings/repos")
DOCKER_DIR = f"{INSTALL_ROOT}/docker"
logger = configure_file_logger("run.send_task")


def main():
    parser = argparse.ArgumentParser(description="Send task to AI agent")
    parser.add_argument("--project", required=True, help="Project name (as configured in repos.json)")
    parser.add_argument("--instruction", required=True, help="Instruction for the agent")
    parser.add_argument("--model", help="Optional Ollama model override for this task")
    parser.add_argument("--wait", action="store_true", help="Wait for result (max 60 seconds)")

    args = parser.parse_args()

    repos = get_repository_map()
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

    task = create_task_payload(
        project=args.project,
        instruction=args.instruction,
        model=args.model,
        submitted_by="cli",
    )
    submit_task(r, task)
    logger.info("Queued task %s for project %s via CLI", task["task_id"], args.project)

    print("Task sent to agent")
    print(f"  Task ID: {task['task_id']}")
    print(f"  Project: {args.project}")
    if task["model"]:
        print(f"  Model: {task['model']}")
    print(f"  Instruction: {args.instruction[:80]}...")

    if args.wait:
        print("\nWaiting for result...")

        start_time = time.time()
        timeout = 60

        while True:
            result = get_task(r, task["task_id"])
            if result and result.get("status") in {"completed", "failed"}:
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
            time.sleep(1)

    print("\nTo check status:")
    print(f"  redis-cli HGETALL task:{task['task_id']}")


if __name__ == "__main__":
    main()
