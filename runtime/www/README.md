# Web Pages

This folder contains the rendered HTML pages served by the API gateway.

Its purpose is to keep the web-facing pages in a dedicated runtime subfolder instead of mixing them with Python modules.

## Files

These pages are served by the API gateway on port `8000`.

| File | Purpose | URL |
|------|---------|-----|
| `index.html` | Main dashboard page linking to all web actions, submitting tasks, and viewing recent task activity. | `http://<vm-ip>:8000/` |
| `chat.html` | Browser chat page for talking directly to an installed Ollama model through the API gateway. | `http://<vm-ip>:8000/chat` |
| `add-remove-components.html` | Component page for installing and removing Ollama models after setup. | `http://<vm-ip>:8000/add-remove-components` |
| `repos.html` | Configuration page for adding, editing, and removing managed Git repositories. | `http://<vm-ip>:8000/repos` |
| `updates.html` | Software update page for checking and applying live-update safe changes. | `http://<vm-ip>:8000/updates` |
| `task_detail.html` | Detail page for a single queued or completed task. | `http://<vm-ip>:8000/tasks/<task_id>` |
| `status.html` | Status page showing the shared activity log and a clear-log action. | `http://<vm-ip>:8000/status` |

Notes:

- Replace `<vm-ip>` with the IP address or hostname of the VM on your LAN
- `task_detail.html` is a dynamic page, so `<task_id>` must be replaced with a real task ID
