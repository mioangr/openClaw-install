#!/usr/bin/env python3
"""
List all configured repositories.

Usage:
    ./list_repos.py
    ./list_repos.py --verbose
"""

import argparse
import json
import os
import sys

CONFIG_PATH = os.getenv("CONFIG_REPO_PATH", "/home/aiuser/settings/repos")
CONFIG_FILE = os.path.join(CONFIG_PATH, "repos.json")

def main():
    parser = argparse.ArgumentParser(description="List configured repositories")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed information")
    args = parser.parse_args()
    
    if not os.path.exists(CONFIG_FILE):
        print(f"Error: Config file not found at {CONFIG_FILE}")
        print("Run setup.sh first to create the configuration")
        sys.exit(1)
    
    with open(CONFIG_FILE, 'r') as f:
        data = json.load(f)
    
    repos = data.get("repos", [])
    
    if not repos:
        print("No repositories configured")
        print("\nTo add a repository:")
        print("  ./add_repo.py --name my-project --url https://github.com/user/repo")
        return
    
    print(f"\n{'='*60}")
    print(f"Configured Repositories ({len(repos)} total)")
    print(f"{'='*60}\n")
    
    for i, repo in enumerate(repos, 1):
        print(f"{i}. {repo['name']}")
        print(f"   URL: {repo['url']}")
        print(f"   Branch: {repo.get('branch', 'main')}")
        
        if args.verbose and repo.get('description'):
            print(f"   Description: {repo['description']}")
        
        print()

if __name__ == "__main__":
    main()