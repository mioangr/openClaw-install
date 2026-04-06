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
      "branch": "main"
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

### Managing Repositories
Edit the JSON file directly:
```bash
nano /home/aiuser/local-ai-agent/settings/repos/repos.json
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
      "branch": "main"
    },
    {
      "name": "work-api",
      "url": "https://github.com/company/api-gateway",
      "branch": "develop"
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
      "branch": "main"
    }
  ]
}
```
