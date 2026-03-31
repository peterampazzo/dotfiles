#!/bin/bash

# Git Credentials Setup with 1Password
# This script helps configure Git to use 1Password for credentials

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    cat << EOF
${BLUE}Git Credentials Setup${NC}

Usage: ./scripts/git-setup.sh [command]

Commands:
  ssh             Setup SSH authentication with GitHub
  token           Setup personal access token authentication
  status          Check current Git configuration
  test            Test Git authentication

Authentication Methods:
  SSH (Recommended):
    - Secure SSH key-based authentication
    - Key stored in ~/.ssh, passphrase in 1Password
    - Works across CLI, IDE, and git tools

  Token (Simple):
    - GitHub personal access token
    - Token stored in 1Password
    - Useful for CI/CD or scripts

Examples:
  ./scripts/git-setup.sh ssh      # Setup SSH keys
  ./scripts/git-setup.sh token    # Setup GitHub token
  ./scripts/git-setup.sh status   # Check current setup
  ./scripts/git-setup.sh test     # Test authentication
EOF
}

# Check prerequisites
check_prereqs() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git not installed${NC}"
        exit 1
    fi

    if ! command -v op &> /dev/null; then
        echo -e "${RED}❌ 1Password CLI not installed${NC}"
        echo "Install with: brew install 1password-cli"
        exit 1
    fi
}

# Setup SSH authentication
setup_ssh() {
    echo -e "${BLUE}🔑 Setting up SSH authentication...${NC}"
    
    local ssh_key=~/.ssh/id_ed25519
    
    # Check if key exists
    if [ -f "$ssh_key" ]; then
        echo -e "${YELLOW}⚠️  SSH key already exists at $ssh_key${NC}"
        read -p "Use existing key? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Generating new key..."
            ssh-keygen -t ed25519 -C "$(git config user.email)" -f "$ssh_key" -N ""
        fi
    else
        echo "Generating SSH key..."
        mkdir -p ~/.ssh
        ssh-keygen -t ed25519 -C "$(git config user.email)" -f "$ssh_key" -N ""
        chmod 600 "$ssh_key"
        chmod 644 "$ssh_key.pub"
    fi

    echo -e "${GREEN}✅ SSH key ready: $ssh_key${NC}"
    echo -e "${BLUE}📋 Add this public key to GitHub:${NC}"
    echo ""
    cat "$ssh_key.pub"
    echo ""
    echo -e "${BLUE}Visit: https://github.com/settings/keys → New SSH key${NC}"
    echo ""

    # Configure SSH config file
    if [ ! -f ~/.ssh/config ]; then
        cat > ~/.ssh/config << 'SSHEOF'
Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes

Host gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
SSHEOF
        echo -e "${GREEN}✅ Created ~/.ssh/config${NC}"
    else
        echo -e "${YELLOW}⚠️  ~/.ssh/config already exists${NC}"
    fi

    echo -e "${GREEN}✅ SSH setup complete!${NC}"
    echo "Test with: ssh -T git@github.com"
}

# Setup token authentication
setup_token() {
    echo -e "${BLUE}🔐 Setting up token authentication...${NC}"
    
    local vault="dev"
    local git_service=$1
    local token_url=""
    local token="$2"

    if [ -z "$git_service" ]; then
        read -p "GitHub or GitLab? (github/gitlab) " git_service
    fi

    case "$git_service" in
        github)
            token_url="https://github.com/settings/tokens"
            token_name="github_token"
            ;;
        gitlab)
            token_url="https://gitlab.com/-/profile/personal_access_tokens"
            token_name="gitlab_token"
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $git_service${NC}"
            return 1
            ;;
    esac

    echo -e "${BLUE}📋 Create a personal access token:${NC}"
    echo "Visit: $token_url"
    echo ""
    echo "For GitHub:"
    echo "  - Select 'repo' scope for private/public repos"
    echo "  - Select 'read:user' for user profile"
    echo ""

    if [ -z "$token" ]; then
        read -sp "Paste your token: " token
        echo
    fi

    # Store in 1Password
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/secrets.sh" save "$vault" "$token_name" "$token"

    echo ""
    echo -e "${GREEN}✅ Token stored in 1Password vault '$vault'${NC}"
    echo "Retrieve with: ./scripts/secrets.sh get $vault $token_name"
}

# Check current setup
check_status() {
    echo -e "${BLUE}📊 Git Configuration Status${NC}"
    echo ""
    
    echo "User Configuration:"
    git config --list | grep "^user\." || echo "  ❌ Not configured"
    echo ""

    echo "Credential Helper:"
    git config credential.helper || echo "  ❌ Not configured (using Keychain by default)"
    echo ""

    echo "SSH Key Status:"
    if [ -f ~/.ssh/id_ed25519 ]; then
        echo "  ✅ SSH key found: ~/.ssh/id_ed25519"
    else
        echo "  ❌ SSH key not found"
    fi
    echo ""

    echo "1Password Tokens:"
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if "$SCRIPT_DIR/secrets.sh" get "dev" "github_token" &>/dev/null; then
        echo "  ✅ GitHub token stored in 1Password"
    else
        echo "  ❌ GitHub token not in 1Password"
    fi

    if "$SCRIPT_DIR/secrets.sh" get "dev" "gitlab_token" &>/dev/null; then
        echo "  ✅ GitLab token stored in 1Password"
    else
        echo "  ❌ GitLab token not in 1Password"
    fi
}

# Test Git authentication
test_auth() {
    echo -e "${BLUE}🧪 Testing Git authentication...${NC}"
    echo ""

    if [ -f ~/.ssh/id_ed25519 ]; then
        echo "SSH Test:"
        ssh -T git@github.com 2>&1 || true
        echo ""
    fi

    echo -e "${BLUE}Git Clone Test:${NC}"
    echo "Try cloning a public repo:"
    echo "  git clone git@github.com:YOUR_USERNAME/dotfiles.git"
    echo "Or with token:"
    echo "  token=\$(./scripts/secrets.sh get dev github_token)"
    echo "  git clone https://YOUR_USERNAME:\$token@github.com/YOUR_USERNAME/dotfiles.git"
}

# Main
check_prereqs

case "${1:-}" in
    ssh)
        setup_ssh
        ;;
    token)
        setup_token "${2:-}" "${3:-}"
        ;;
    status)
        check_status
        ;;
    test)
        test_auth
        ;;
    help|-h|--help)
        show_usage
        ;;
    *)
        show_usage
        ;;
esac
