#!/bin/bash

# 1Password CLI Setup
# This script helps manage credentials using 1Password's `op` CLI tool
# Installation: brew install 1password-cli
# Then: op account add (authenticate)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if op CLI is installed
if ! command -v op &> /dev/null; then
    echo -e "${RED}❌ 1Password CLI not installed${NC}"
    echo "Install with: brew install 1password-cli"
    exit 1
fi

# Check if authenticated to 1Password CLI
is_op_authenticated() {
    # Prefer whoami on modern CLI, fallback to vault list for compatibility.
    op whoami > /dev/null 2>&1 || op vault list > /dev/null 2>&1
}

# Check if signed in
if ! is_op_authenticated; then
    echo -e "${YELLOW}🔑 Not signed into 1Password. Signing in...${NC}"
    op signin || op account add
fi

show_usage() {
    cat << EOF
${BLUE}1Password Credential Manager${NC}

Usage: ./scripts/secrets.sh [command] [options]

Commands:
  save VAULT SECRET_NAME SECRET_VALUE
      Save a secret to 1Password vault
      Example: ./scripts/secrets.sh save dev api_key "xyz123abc"

  get VAULT SECRET_NAME
      Retrieve a secret from 1Password vault
      Example: ./scripts/secrets.sh get dev api_key

  list VAULT
      List all secrets in a vault
      Example: ./scripts/secrets.sh list dev

  export VAULT VARIABLE_NAME SECRET_NAME
      Export secret as environment variable
      Example: ./scripts/secrets.sh export dev DATABASE_URL db_password
      Result: export DATABASE_URL="<secret_value>"

  create-vault VAULT_NAME
      Create a new vault
      Example: ./scripts/secrets.sh create-vault dev-secrets

Vaults:
  dev       - Development credentials
  prod      - Production credentials (use with caution!)

Environment Setup:
  1. Create vaults: ./scripts/secrets.sh create-vault dev
  2. Save secrets: ./scripts/secrets.sh save dev slack_token "xoxb-xxx"
  3. Load in shell: eval "\$(./scripts/secrets.sh export dev SLACK_TOKEN slack_token)"

For more info: https://1password.com/devs/
EOF
}

# Save secret to 1Password
save_secret() {
    local vault=$1
    local secret_name=$2
    local secret_value=$3

    if [ -z "$vault" ] || [ -z "$secret_name" ] || [ -z "$secret_value" ]; then
        echo -e "${RED}❌ Usage: save VAULT SECRET_NAME SECRET_VALUE${NC}"
        return 1
    fi

    op item create --vault "$vault" --category "password" \
        --title "$secret_name" \
        password="$secret_value" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Secret already exists. Updating...${NC}"
        op item edit "$secret_name" --vault "$vault" password="$secret_value" 2>/dev/null
    }

    echo -e "${GREEN}✅ Saved '$secret_name' to vault '$vault'${NC}"
}

# Retrieve secret from 1Password
get_secret() {
    local vault=$1
    local secret_name=$2

    if [ -z "$vault" ] || [ -z "$secret_name" ]; then
        echo -e "${RED}❌ Usage: get VAULT SECRET_NAME${NC}"
        return 1
    fi

    op item get "$secret_name" --vault "$vault" --fields "password" 2>/dev/null || {
        echo -e "${RED}❌ Secret '$secret_name' not found in vault '$vault'${NC}"
        return 1
    }
}

# List all secrets in vault
list_secrets() {
    local vault=$1

    if [ -z "$vault" ]; then
        echo -e "${RED}❌ Usage: list VAULT${NC}"
        return 1
    fi

    echo -e "${BLUE}Secrets in vault: $vault${NC}"
    op item list --vault "$vault" --format json | jq -r '.[] | "\(.title)"'
}

# Export secret as environment variable
export_secret() {
    local vault=$1
    local var_name=$2
    local secret_name=$3

    if [ -z "$vault" ] || [ -z "$var_name" ] || [ -z "$secret_name" ]; then
        echo -e "${RED}❌ Usage: export VAULT VARIABLE_NAME SECRET_NAME${NC}"
        return 1
    fi

    local secret_value
    secret_value=$(get_secret "$vault" "$secret_name") || return 1

    echo "export $var_name='$secret_value'"
}

# Create new vault
create_vault() {
    local vault_name=$1

    if [ -z "$vault_name" ]; then
        echo -e "${RED}❌ Usage: create-vault VAULT_NAME${NC}"
        return 1
    fi

    op vault create "$vault_name" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Vault '$vault_name' already exists${NC}"
        return 0
    }

    echo -e "${GREEN}✅ Created vault: $vault_name${NC}"
}

# Main logic
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    save)
        save_secret "$2" "$3" "$4"
        ;;
    get)
        get_secret "$2" "$3"
        ;;
    list)
        list_secrets "$2"
        ;;
    export)
        export_secret "$2" "$3" "$4"
        ;;
    create-vault)
        create_vault "$2"
        ;;
    help|-h|--help)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
