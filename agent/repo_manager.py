#!/usr/bin/env python3
"""
================================================================================
Repository Manager - Utilities for managing repository configurations
================================================================================
Purpose: Helper functions for adding, removing, and listing repositories
         in the configuration file.

Usage:
    python repo_manager.py --list
    python repo_manager.py --add --name my-project --url https://github.com/user/repo
    python repo_manager.py --remove --name my-project
================================================================================
"""

import json
import os
import sys
import argparse
from typing import Dict, List

CONFIG_PATH = os.getenv("CONFIG_REPO_PATH", "/settings/repos")
CONFIG_FILE = os.path.join(CONFIG_PATH, "repos.json")

def load_config() -> Dict:
    """Load the repository configuration file"""
    if not os.path.exists(CONFIG_FILE):
        # Create default config
        default_config = {"repos": []}
        os.makedirs(CONFIG_PATH, exist_ok=True)
        with open(CONFIG_FILE, 'w') as f:
            json.dump(default_config, f, indent=2)
        return default_config
    
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def save_config(config: Dict) -> None:
    """Save the repository configuration file"""
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

def list_repos() -> List[Dict]:
    """List all configured repositories"""
    config = load_config()
    return config.get("repos", [])

def add_repo(name: str, url: str, branch: str = "main", description: str = "") -> bool:
    """Add a new repository to the configuration"""
    config = load_config()
    repos = config.get("repos", [])
    
    # Check if name already exists
    for repo in repos:
        if repo["name"] == name:
            print(f"Error: Repository with name '{name}' already exists")
            return False
    
    repos.append({
        "name": name,
        "url": url,
        "branch": branch,
        "description": description
    })
    
    config["repos"] = repos
    save_config(config)
    print(f"Added repository: {name} -> {url}")
    return True

def remove_repo(name: str) -> bool:
    """Remove a repository from the configuration"""
    config = load_config()
    repos = config.get("repos", [])
    
    original_count = len(repos)
    config["repos"] = [repo for repo in repos if repo["name"] != name]
    
    if len(config["repos"]) == original_count:
        print(f"Error: Repository '{name}' not found")
        return False
    
    save_config(config)
    print(f"Removed repository: {name}")
    return True

def main():
    parser = argparse.ArgumentParser(description="Manage repository configurations")
    parser.add_argument("--list", action="store_true", help="List all repositories")
    parser.add_argument("--add", action="store_true", help="Add a new repository")
    parser.add_argument("--remove", action="store_true", help="Remove a repository")
    parser.add_argument("--name", help="Repository name")
    parser.add_argument("--url", help="Repository URL (for --add)")
    parser.add_argument("--branch", default="main", help="Default branch (default: main)")
    parser.add_argument("--description", default="", help="Repository description")
    
    args = parser.parse_args()
    
    if args.list:
        repos = list_repos()
        if not repos:
            print("No repositories configured")
        else:
            print("\nConfigured repositories:")
            print("-" * 60)
            for repo in repos:
                print(f"  Name: {repo['name']}")
                print(f"  URL:  {repo['url']}")
                print(f"  Branch: {repo['branch']}")
                if repo.get('description'):
                    print(f"  Desc: {repo['description']}")
                print()
    
    elif args.add:
        if not args.name or not args.url:
            print("Error: --name and --url are required for --add")
            sys.exit(1)
        add_repo(args.name, args.url, args.branch, args.description)
    
    elif args.remove:
        if not args.name:
            print("Error: --name is required for --remove")
            sys.exit(1)
        remove_repo(args.name)
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main()