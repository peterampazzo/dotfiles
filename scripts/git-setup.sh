#!/bin/bash

# Git Setup: gh CLI auth + SSH key + signed commits + 1Password backup
# Usage: ./scripts/git-setup.sh [setup|status|test]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_SCRIPT="$SCRIPT_DIR/secrets.sh"
VAULT="Private"
SSH_KEY="$HOME/.ssh/id_ed25519"

show_usage() {
    cat << EOF
${BLUE}Git Setup${NC}
Authenticate with GitHub, generate SSH key, enable signed commits, and backup to 1Password.

Usage: ./scripts/git-setup.sh [command]

Commands:
  setup     Full setup: gh auth → SSH key → commit signing → 1Password backup
  status    Show current Git/SSH/signing configuration
  test      Test SSH auth and commit signing

Steps performed by 'setup':
  1. Authenticate with GitHub via gh CLI (SSH protocol)
  2. Generate Ed25519 SSH key (if missing)
  3. Upload SSH key to GitHub (auth + signing)
  4. Configure git to sign commits with SSH key
  5. Backup SSH public key to 1Password
EOF
}

check_prereqs() {
    local missing=0
    for cmd in git gh op; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}❌ $cmd not installed${NC}"
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo "Install with: brew install git gh 1password-cli"
        exit 1
    fi
}

# ── Step 1: gh CLI authentication ──────────────────────────────────────────

setup_gh_auth() {
    echo -e "${BLUE}1️⃣  GitHub CLI authentication${NC}"

    if gh auth status &>/dev/null; then
        echo -e "${GREEN}✅ Already authenticated with GitHub CLI${NC}"
        gh auth status 2>&1 | sed 's/^/   /'
        # Ensure signing key scope is available
        if ! gh auth token -h github.com 2>/dev/null | xargs -I{} gh api user/ssh_signing_keys --per-page 1 &>/dev/null; then
            echo "Adding signing key scope..."
            gh auth refresh -h github.com -s admin:ssh_signing_key
        fi
    else
        echo "Logging in via gh CLI (SSH protocol)..."
        if [ -f "$SSH_KEY" ]; then
            gh auth login --git-protocol ssh --web --skip-ssh-key -s admin:ssh_signing_key
        else
            gh auth login --git-protocol ssh --web -s admin:ssh_signing_key
        fi
    fi
    echo ""
}

# ── Step 2: SSH key ────────────────────────────────────────────────────────

setup_ssh_key() {
    echo -e "${BLUE}2️⃣  SSH key${NC}"

    if [ -f "$SSH_KEY" ]; then
        echo -e "${GREEN}✅ SSH key exists: $SSH_KEY${NC}"
    else
        # gh auth login may have created it; if not, generate now
        local email
        email=$(git config --global user.email 2>/dev/null || echo "")
        if [ -z "$email" ]; then
            read -rp "Git email address: " email
            git config --global user.email "$email"
        fi
        echo "Generating Ed25519 SSH key for $email..."
        mkdir -p ~/.ssh
        ssh-keygen -t ed25519 -C "$email" -f "$SSH_KEY" -N ""
        chmod 600 "$SSH_KEY"
        chmod 644 "$SSH_KEY.pub"
        echo -e "${GREEN}✅ SSH key generated${NC}"
    fi
    echo ""
}

# ── Step 3: Upload key to GitHub (auth + signing) ─────────────────────────

upload_ssh_key() {
    echo -e "${BLUE}3️⃣  Upload SSH key to GitHub${NC}"

    local pub_key
    pub_key=$(cat "$SSH_KEY.pub")
    local key_title="dotfiles-$(hostname -s)-$(date +%Y%m%d)"

    # Upload as authentication key
    if gh ssh-key list 2>/dev/null | grep -qF "$(awk '{print $2}' "$SSH_KEY.pub")"; then
        echo -e "${GREEN}✅ Auth key already on GitHub${NC}"
    else
        gh ssh-key add "$SSH_KEY.pub" --title "$key_title" --type authentication
        echo -e "${GREEN}✅ Auth key uploaded to GitHub${NC}"
    fi

    # Upload as signing key
    if gh ssh-key list 2>/dev/null | grep -q "signing"; then
        echo -e "${GREEN}✅ Signing key already on GitHub${NC}"
    else
        gh ssh-key add "$SSH_KEY.pub" --title "${key_title}-signing" --type signing
        echo -e "${GREEN}✅ Signing key uploaded to GitHub${NC}"
    fi
    echo ""
}

# ── Step 4: Configure git for SSH commit signing ──────────────────────────

configure_signing() {
    echo -e "${BLUE}4️⃣  Configure commit signing${NC}"

    # Set identity if missing
    if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
        read -rp "Git name: " name
        git config --global user.name "$name"
    fi

    # SSH signing config
    git config --global gpg.format ssh
    git config --global user.signingkey "$SSH_KEY.pub"
    git config --global commit.gpgsign true
    git config --global tag.gpgsign true

    # Allowed signers file (for local verification)
    local allowed_signers="$HOME/.ssh/allowed_signers"
    local email
    email=$(git config --global user.email)
    echo "$email $(cat "$SSH_KEY.pub")" > "$allowed_signers"
    git config --global gpg.ssh.allowedSignersFile "$allowed_signers"

    # SSH config for GitHub
    if ! grep -q "Host github.com" ~/.ssh/config 2>/dev/null; then
        mkdir -p ~/.ssh
        cat >> ~/.ssh/config << 'SSHEOF'

Host github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
    IdentitiesOnly yes
SSHEOF
        echo -e "${GREEN}✅ Updated ~/.ssh/config${NC}"
    fi

    # Use gh as credential helper for HTTPS fallback
    gh auth setup-git 2>/dev/null || true

    echo -e "${GREEN}✅ Commit signing enabled (SSH)${NC}"
    echo ""
}

# ── Step 5: Backup to 1Password ───────────────────────────────────────────

backup_to_1password() {
    echo -e "${BLUE}5️⃣  Backup SSH key to 1Password${NC}"

    if op whoami &>/dev/null || op vault list &>/dev/null; then
        local item_name="GitHub SSH Signing Key"

        # Check if item already exists
        if op item get "$item_name" --vault "$VAULT" &>/dev/null; then
            echo -e "${YELLOW}⚠️  '$item_name' already exists in 1Password — skipping${NC}"
            echo "  To replace, delete it first: op item delete '$item_name' --vault $VAULT"
        else
            op item create --category "SSH Key" \
                --title "$item_name" \
                --vault "$VAULT" < "$SSH_KEY"
            echo -e "${GREEN}✅ SSH key saved as native SSH Key item in 1Password vault '$VAULT'${NC}"
        fi
        echo -e "${YELLOW}ℹ️  Enable 1Password SSH agent (Settings → Developer) to use it for signing${NC}"
    else
        echo -e "${YELLOW}⚠️  Not signed into 1Password, skipping backup${NC}"
    fi
    echo ""
}

# ── Status ─────────────────────────────────────────────────────────────────

show_status() {
    echo -e "${BLUE}📊 Git Configuration${NC}"
    echo ""
    echo "  Name:           $(git config --global user.name 2>/dev/null || echo '❌ not set')"
    echo "  Email:          $(git config --global user.email 2>/dev/null || echo '❌ not set')"
    echo ""

    echo -e "${BLUE}🔑 SSH Key${NC}"
    if [ -f "$SSH_KEY" ]; then
        echo "  Key:            ✅ $SSH_KEY"
        echo "  Fingerprint:    $(ssh-keygen -lf "$SSH_KEY.pub" 2>/dev/null | awk '{print $2}')"
    else
        echo "  Key:            ❌ not found"
    fi
    echo ""

    echo -e "${BLUE}✍️  Commit Signing${NC}"
    local fmt=$(git config --global gpg.format 2>/dev/null || echo "none")
    local sign=$(git config --global commit.gpgsign 2>/dev/null || echo "false")
    local skey=$(git config --global user.signingkey 2>/dev/null || echo "none")
    echo "  Format:         $fmt"
    echo "  Auto-sign:      $sign"
    echo "  Signing key:    $skey"
    echo ""

    echo -e "${BLUE}🐙 GitHub CLI${NC}"
    if gh auth status &>/dev/null; then
        echo "  Auth:           ✅ authenticated"
        gh auth status 2>&1 | grep "Token\|account" | sed 's/^/  /'
    else
        echo "  Auth:           ❌ not authenticated"
    fi
    echo ""

    echo -e "${BLUE}☁️  1Password${NC}"
    if op whoami &>/dev/null 2>&1; then
        echo "  CLI:            ✅ signed in"
    else
        echo "  CLI:            ❌ not signed in"
    fi
}

# ── Test ───────────────────────────────────────────────────────────────────

run_test() {
    echo -e "${BLUE}🧪 Testing...${NC}"
    echo ""

    echo "SSH connection:"
    ssh -T git@github.com 2>&1 | sed 's/^/  /' || true
    echo ""

    echo "Signed commit test:"
    local tmpdir
    tmpdir=$(mktemp -d)
    (
        cd "$tmpdir"
        git init -q
        git config user.email "$(git config --global user.email)"
        git config user.name "$(git config --global user.name)"
        git config gpg.format ssh
        git config user.signingkey "$SSH_KEY.pub"
        git config commit.gpgsign true
        git config gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"
        echo "test" > test.txt
        git add test.txt
        if git commit -q -S -m "test signed commit" 2>/dev/null; then
            echo -e "  ${GREEN}✅ Signed commit succeeded${NC}"
            git log --show-signature -1 2>&1 | grep -E "Good|Signature" | sed 's/^/  /'
        else
            echo -e "  ${RED}❌ Signed commit failed${NC}"
        fi
    )
    rm -rf "$tmpdir"
}

# ── Main ───────────────────────────────────────────────────────────────────

check_prereqs

case "${1:-}" in
    setup)
        setup_gh_auth
        setup_ssh_key
        upload_ssh_key
        configure_signing
        backup_to_1password
        echo -e "${GREEN}🎉 Git setup complete! All commits will now be signed.${NC}"
        ;;
    status)
        show_status
        ;;
    test)
        run_test
        ;;
    help|-h|--help)
        show_usage
        ;;
    *)
        show_usage
        ;;
esac
