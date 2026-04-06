# Repository Configuration

This folder stores configuration for all repositories that the AI agent can work with.

## File: `repos.json`

This JSON file defines which repositories the agent can access and modify.

### Format

```json
{
  "repos": [
    {
      "name": "unique-project-name",
      "url": "https://github.com/username/repository",
      "branch": "main",
      "description": "Human-readable description"
    }
  ]
}
```

### Fields
Field |	Required | Description |
|------|---------|---------|
| name	| Yes	| Short identifier used in commands (e.g., --project my-app) |
| url	| Yes	| Full GitHub URL (HTTPS format) |
| branch	| Yes	| Default branch to create PRs against |
| description	| No	| For your reference only |

### Adding a Repository
#### Method 1: Edit manually

```bash
nano /home/aiuser/config-repos/repos.json
```

#### Method 2: Use helper script

```bash
/home/aiuser/scripts/add_repo.py --name my-project --url https://github.com/user/repo
```

### Security Note
The GitHub token in .env must have access to all repositories listed here. If a repository is private, the token must have repo scope.

#### Example
```json
{
  "repos": [
    {
      "name": "personal-blog",
      "url": "https://github.com/john/blog",
      "branch": "main",
      "description": "My personal blog"
    },
    {
      "name": "work-api",
      "url": "https://github.com/company/api-gateway",
      "branch": "develop",
      "description": "Company API - requires special token"
    }
  ]
}
```

#### `config-repos/repos.json`

```json
{
  "repos": [
    {
      "name": "example-project",
      "url": "https://github.com/mioangr/YOUR_REPO",
      "branch": "main",
      "description": "Replace with your actual repository"
    }
  ]
}
```