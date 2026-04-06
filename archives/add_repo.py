#!/usr/bin/env python3
"""
Add a new repository to the configuration.

Usage:
    ./add_repo.py --name my-project --url https://github.com/user/repo
    ./add_repo.py --name my-project --url https://github.com/user/repo --branch develop --description "My API service"
"""

import argparse
import json
import os
import sys

CONFIG_PATH = os.getenv("CONFIG_REPO_PATH", "/home/aiuser/settings/repos")
CONFIG_FILE = os.path.join(CONFIG_PATH, "repos.json")

def load_config():
    """Load existing configuration"""
    if not os.path.exists(CONFIG_FILE):
        return {"repos": []}
    
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def save_config(config):
    """Save configuration"""
    os.makedirs(CONFIG_PATH, exist_ok=True)
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

def main():
    parser = argparse.ArgumentParser(description="Add a repository to configuration")
    parser.add_argument("--name", required=True, help="Unique project name")
    parser.add_argument("--url", required=True, help="GitHub repository URL (HTTPS format)")
    parser.add_argument("--branch", default="main", help="Default branch (default: main)")
    parser.add_argument("--description", default="", help="Optional description")
    
    args = parser.parse_args()
    
    # Validate URL format
    if not args.url.startswith("https://github.com/"):
        print(f"Warning: URL doesn't look like a GitHub HTTPS URL: {args.url}")
        response = input("Continue anyway? (y/n) ")
        if response.lower() != 'y':
            sys.exit(1)
    
    # Load existing config
    config = load_config()
    repos = config.get("repos", [])
    
    # Check for duplicate name
    for repo in repos:
        if repo["name"] == args.name:
            print(f"Error: Repository with name '{args.name}' already exists")
            print(f"  Existing: {repo['url']}")
            sys.exit(1)
    
    # Add new repository
    new_repo = {
        "name": args.name,
        "url": args.url,
        "branch": args.branch,
        "description": args.description
    }
    
    repos.append(new_repo)
    config["repos"] = repos
    save_config(config)
    
    print(f"✓ Added repository: {args.name}")
    print(f"  URL: {args.url}")
    print(f"  Branch: {args.branch}")
    if args.description:
        print(f"  Description: {args.description}")
    
    print("\nYou can now send tasks to this project:")
    print(f"  ./send_task.py --project {args.name} --instruction 'Your instruction'")

if __name__ == "__main__":
    main()