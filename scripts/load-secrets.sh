#!/bin/bash

# Load Environment Variables from 1Password
# Usage: source scripts/load-secrets.sh
# Or: eval "$(./scripts/load-secrets.sh)" in your shell config

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_SCRIPT="$SCRIPT_DIR/secrets.sh"

# Check if secrets script exists
if [ ! -f "$SECRETS_SCRIPT" ]; then
    echo "❌ secrets.sh not found at $SECRETS_SCRIPT"
    return 1 2>/dev/null || exit 1
fi

# Define which secrets to load from which vaults
# Format: VAULT:SECRET_NAME:VARIABLE_NAME

# Development secrets
load_secret() {
    local vault=$1
    local secret_name=$2
    local var_name=$3

    if [ -z "$vault" ] || [ -z "$secret_name" ] || [ -z "$var_name" ]; then
        return 1
    fi

    local value
    value=$("$SECRETS_SCRIPT" get "$vault" "$secret_name" 2>/dev/null) || return 1
    
    export "$var_name=$value"
    echo "✅ Loaded $var_name from 1Password"
}

# Example: Load development API key
# load_secret "dev" "slack_token" "SLACK_TOKEN"
# load_secret "dev" "github_token" "GITHUB_TOKEN"
# load_secret "dev" "api_key" "API_KEY"

# Production secrets (use with caution!)
# load_secret "prod" "database_url" "DATABASE_URL"
# load_secret "prod" "api_key" "PROD_API_KEY"

echo "✅ Secret loader ready"
echo "Define which secrets to load in load-secrets.sh"
