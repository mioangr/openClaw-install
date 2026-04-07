#!/bin/bash
# =============================================================================
# Common Functions for Setup Scripts
# =============================================================================

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$COMMON_DIR/../.." && pwd)"
INSTALL_CONFIG_FILE="${INSTALL_CONFIG_FILE:-$PROJECT_ROOT/install.conf}"

if [ ! -f "$INSTALL_CONFIG_FILE" ]; then
    echo "ERROR: install config file not found at $INSTALL_CONFIG_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$INSTALL_CONFIG_FILE"

AI_USER="${AI_USER:-aiuser}"
INSTALL_DEST_DIR="${INSTALL_DEST_DIR:-local-ai-agent}"
MODEL_NAME="${MODEL_NAME:-qwen2.5-coder:1.5b}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"

AI_HOME="/home/$AI_USER"
INSTALL_ROOT="$AI_HOME/$INSTALL_DEST_DIR"
ENV_FILE="$INSTALL_ROOT/.env"
DOCKER_DIR="$INSTALL_ROOT/docker"
AGENT_DIR="$INSTALL_ROOT/agent"
SCRIPTS_DIR="$INSTALL_ROOT/scripts"
SETTINGS_DIR="$INSTALL_ROOT/settings"
REPOS_DIR="$SETTINGS_DIR/repos"
LOGS_DIR="$INSTALL_ROOT/logs"
WORKSPACE_DIR="$INSTALL_ROOT/workspace"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"

export PROJECT_ROOT
export INSTALL_CONFIG_FILE
export AI_USER
export INSTALL_DEST_DIR
export MODEL_NAME
export LOG_LEVEL
export AI_HOME
export INSTALL_ROOT
export ENV_FILE
export DOCKER_DIR
export AGENT_DIR
export SCRIPTS_DIR
export SETTINGS_DIR
export REPOS_DIR
export LOGS_DIR
export WORKSPACE_DIR
export COMPOSE_FILE

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}===========================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===========================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}> $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

die() {
    local exit_code=$1
    local error_msg=$2
    local fix_msg=$3

    print_error "$error_msg"

    if [ -n "$fix_msg" ]; then
        echo ""
        echo -e "${YELLOW}How to fix:${NC}"
        echo "  $fix_msg"
        echo ""
        echo -e "${YELLOW}For help, check:${NC}"
        echo "  - The README.md file"
        echo "  - The error logs above"
    fi

    exit "$exit_code"
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

check_error() {
    local status=$?
    local message="$1"
    if [ $status -ne 0 ]; then
        die 1 "$message" "Review the error above and try again. If the problem persists, check the documentation."
    fi
}

run_safe() {
    local cmd="$1"
    local error_msg="$2"

    print_step "Running: $cmd"
    eval "$cmd"
    check_error "$error_msg"
}

ensure_interactive_input() {
    if [ -t 0 ]; then
        return 0
    fi

    if [ -r /dev/tty ]; then
        return 0
    fi

    die 1 \
        "Interactive input required, but no terminal is attached" \
        "Run the installer from an interactive shell or use SSH with a TTY."
}

prompt_yes_no() {
    local prompt="$1"
    local result_var="$2"
    local answer

    ensure_interactive_input

    if [ -t 0 ]; then
        read -p "$prompt" -n 1 -r answer
    else
        read -p "$prompt" -n 1 -r answer < /dev/tty
    fi
    echo

    printf -v "$result_var" '%s' "$answer"
}

prompt_input() {
    local prompt="$1"
    local result_var="$2"
    local answer

    ensure_interactive_input

    if [ -t 0 ]; then
        read -p "$prompt" -r answer
    else
        read -p "$prompt" -r answer < /dev/tty
    fi

    printf -v "$result_var" '%s' "$answer"
}

prompt_secret() {
    local prompt="$1"
    local result_var="$2"
    local answer

    ensure_interactive_input

    if [ -t 0 ]; then
        read -sp "$prompt" -r answer
    else
        read -sp "$prompt" -r answer < /dev/tty
    fi
    echo

    printf -v "$result_var" '%s' "$answer"
}

prompt_enter() {
    local prompt="$1"

    ensure_interactive_input

    if [ -t 0 ]; then
        read -p "$prompt" -r
    else
        read -p "$prompt" -r < /dev/tty
    fi
}

run_interactive_command() {
    ensure_interactive_input

    if [ -t 0 ]; then
        "$@"
    else
        "$@" < /dev/tty > /dev/tty
    fi
}
