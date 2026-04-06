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

### Managing Repositories
Edit the JSON file directly:
```bash
nano /home/aiuser/settings/repos/repos.json
```

### Security Note
The GitHub token in .env must have access to all repositories listed here. If a repository is private, the token must have repo scope.

#### Example
```json
{
  "repos": [
    {
      "name": "personal-blog",
      "url": "https://github.com/a_username/blog",
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

#### `settings/repos/repos.json`

```json
{
  "repos": [
    {
      "name": "example-project",
      "url": "https://github.com/yourusername/YOUR_REPO",
      "branch": "main",
      "description": "Replace with your actual repository"
    }
  ]
}
```
