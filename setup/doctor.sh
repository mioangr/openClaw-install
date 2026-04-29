#!/bin/bash
# Diagnose the current installation state without making changes.

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

print_header "Local AI Agent Doctor"

ISSUES=0
WARNINGS=0

ok() {
    echo "  [OK] $1"
}

warn() {
    echo "  [WARN] $1"
    WARNINGS=$((WARNINGS + 1))
}

fail() {
    echo "  [FAIL] $1"
    ISSUES=$((ISSUES + 1))
}

print_step "Checking configuration"
if [ -f "$INSTALL_CONFIG_FILE" ]; then
    ok "Found install config at $INSTALL_CONFIG_FILE"
else
    fail "Missing install config at $INSTALL_CONFIG_FILE"
fi

print_step "Checking user and directories"
if id "$AI_USER" >/dev/null 2>&1; then
    ok "User $AI_USER exists"
else
    fail "User $AI_USER does not exist"
fi

if [ -d "$INSTALL_ROOT" ]; then
    ok "Install root exists at $INSTALL_ROOT"
else
    fail "Install root missing at $INSTALL_ROOT"
fi

if [ -f "$ENV_FILE" ]; then
    ok "Secrets file exists at $ENV_FILE"
else
    warn "Secrets file missing at $ENV_FILE"
fi

if [ -f "$COMPOSE_FILE" ]; then
    ok "Docker Compose file exists at $COMPOSE_FILE"
else
    warn "Docker Compose file missing at $COMPOSE_FILE"
fi

if [ -d "$REPOS_DIR" ]; then
    ok "Repository settings directory exists"
else
    warn "Repository settings directory missing at $REPOS_DIR"
fi

print_step "Checking system dependencies"
if command -v docker >/dev/null 2>&1; then
    ok "Docker CLI available: $(docker --version | cut -d',' -f1)"
else
    fail "Docker CLI not found in PATH"
fi

if command -v python3 >/dev/null 2>&1; then
    ok "Python available: $(python3 --version)"
else
    fail "python3 not found in PATH"
fi

if command -v git >/dev/null 2>&1; then
    ok "Git available: $(git --version)"
else
    fail "git not found in PATH"
fi

print_step "Checking Docker runtime"
if sudo_available_noninteractive; then
    if sudo docker info >/dev/null 2>&1; then
        ok "Docker daemon is reachable"
    else
        fail "Docker daemon is not reachable"
    fi

    for container in ollama redis langgraph-agent api-gateway; do
        if sudo docker ps --format '{{.Names}}' | grep -qx "$container"; then
            status=$(sudo docker ps --filter "name=^/${container}$" --format '{{.Status}}' | head -n1)
            ok "Container $container is running ($status)"
        elif sudo docker ps -a --format '{{.Names}}' | grep -qx "$container"; then
            status=$(sudo docker ps -a --filter "name=^/${container}$" --format '{{.Status}}' | head -n1)
            warn "Container $container exists but is not running ($status)"
        else
            warn "Container $container does not exist"
        fi
    done

    if sudo docker ps --format '{{.Names}}' | grep -qx "ollama"; then
        model_list=$(sudo docker exec ollama ollama list 2>/dev/null || true)
        model_count=$(printf "%s\n" "$model_list" | tail -n +2 | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
        if [ "$model_count" -gt 0 ]; then
            ok "Ollama has $model_count installed model(s)"
        else
            ok "No Ollama models installed yet; install one from /add-remove-components"
        fi
    else
        warn "Skipped model check because the ollama container is not running"
    fi
else
    warn "Skipped privileged Docker checks because sudo requires a password"
fi

echo ""
if [ "$ISSUES" -eq 0 ]; then
    print_step "Doctor finished with no hard failures"
else
    print_error "Doctor found $ISSUES issue(s)"
fi

if [ "$WARNINGS" -gt 0 ]; then
    print_warning "Doctor also found $WARNINGS warning(s)"
fi

if [ "$ISSUES" -gt 0 ]; then
    exit 1
fi
