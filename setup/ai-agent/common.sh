
#### `setup/ai-agent/common.sh`

```bash
#!/bin/bash
# =============================================================================
# Common Functions for Setup Scripts
# =============================================================================
# Purpose: Provides shared error handling and utility functions
# Usage:   source /path/to/common.sh
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print formatted messages
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}▶ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

# Error handling function
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
    
    exit $exit_code
}

# Check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# Check error from last command
check_error() {
    local message="$1"
    if [ $? -ne 0 ]; then
        die 1 "$message" "Review the error above and try again. If the problem persists, check the documentation."
    fi
}

# Run command with error checking
run_safe() {
    local cmd="$1"
    local error_msg="$2"
    
    print_step "Running: $cmd"
    eval $cmd
    check_error "$error_msg"
}