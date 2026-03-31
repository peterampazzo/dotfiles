#!/bin/bash

# Unified Secrets Synchronization
# Backup/restore all sensitive configs to/from 1Password
# Services: AWS, Docker, Kube, GitHub (gh CLI), Git, SSH

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VAULT="dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_SCRIPT="$SCRIPT_DIR/secrets.sh"

show_usage() {
    cat << EOF
${BLUE}Unified Secrets Manager${NC}
Backup and restore all sensitive configurations to 1Password

Usage: ./scripts/secrets-sync.sh [command] [service] [options]

Commands:
  backup [service]           Backup service(s) to 1Password
                             service: aws, docker, kube, github, git, all (default: all)
  
  restore [service]          Restore service(s) from 1Password
                             service: aws, docker, kube, github, git, all (default: all)
  
  list [service]             Show stored secrets
                             service: aws, docker, kube, github, git, all (default: all)
  
  status                     Show backup/restore status for all services
  
  help                       Show this help

Services:
  aws        → \$HOME/.aws (credentials, config)
  docker     → \$HOME/.docker/config.json (registry credentials)
  kube       → \$HOME/.kube/config (cluster credentials)
  github     → GitHub CLI authentication (via \`gh\`)
  git        → Git global config (\$HOME/.gitconfig)
  ssh        → \$HOME/.ssh/ (private keys) - BACKUP ONLY, RESTORE REQUIRES MANUAL VERIFICATION

Examples:
  # Backup everything
  ./scripts/secrets-sync.sh backup

  # Backup only AWS
  ./scripts/secrets-sync.sh backup aws

  # Restore everything
  ./scripts/secrets-sync.sh restore

  # Check what's stored
  ./scripts/secrets-sync.sh status

Setup (first time):
  1. Install 1Password CLI: brew install 1password-cli
  2. Sign in: op account add
  3. Create vault: ./scripts/secrets.sh create-vault dev
  4. Backup everything: ./scripts/secrets-sync.sh backup
  5. On new machine: ./scripts/secrets-sync.sh restore all
EOF
}

# Check prerequisites
check_prereqs() {
    if ! command -v op &> /dev/null; then
        echo -e "${RED}❌ 1Password CLI not installed${NC}"
        echo "Install with: brew install 1password-cli"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq not installed${NC}"
        echo "Install with: brew install jq"
        exit 1
    fi

    # Check 1Password authentication
    if ! is_op_authenticated; then
        echo -e "${YELLOW}🔑 Not signed into 1Password. Run: op signin (or op account add)${NC}"
        exit 1
    fi
}

is_op_authenticated() {
    # Prefer whoami on modern CLI, fallback to vault list for compatibility.
    op whoami > /dev/null 2>&1 || op vault list > /dev/null 2>&1
}

# AWS Backup
backup_aws() {
    echo -e "${BLUE}📦 Backing up AWS credentials...${NC}"
    
    if [ ! -d ~/.aws ]; then
        echo -e "${YELLOW}⚠️  No ~/.aws directory found${NC}"
        return 0
    fi

    # Backup credentials file
    if [ -f ~/.aws/credentials ]; then
        local creds=$(cat ~/.aws/credentials | base64)
        "$SECRETS_SCRIPT" save "$VAULT" "aws_credentials" "$creds" 2>/dev/null || true
        echo -e "${GREEN}✅ AWS credentials backed up${NC}"
    fi

    # Backup config file
    if [ -f ~/.aws/config ]; then
        local config=$(cat ~/.aws/config | base64)
        "$SECRETS_SCRIPT" save "$VAULT" "aws_config" "$config" 2>/dev/null || true
        echo -e "${GREEN}✅ AWS config backed up${NC}"
    fi
}

# AWS Restore
restore_aws() {
    echo -e "${BLUE}🔄 Restoring AWS credentials...${NC}"
    
    mkdir -p ~/.aws
    chmod 700 ~/.aws

    # Restore credentials
    if "$SECRETS_SCRIPT" get "$VAULT" "aws_credentials" &>/dev/null; then
        local creds=$("$SECRETS_SCRIPT" get "$VAULT" "aws_credentials" | base64 -d)
        echo "$creds" > ~/.aws/credentials
        chmod 600 ~/.aws/credentials
        echo -e "${GREEN}✅ AWS credentials restored${NC}"
    fi

    # Restore config
    if "$SECRETS_SCRIPT" get "$VAULT" "aws_config" &>/dev/null; then
        local config=$("$SECRETS_SCRIPT" get "$VAULT" "aws_config" | base64 -d)
        echo "$config" > ~/.aws/config
        chmod 600 ~/.aws/config
        echo -e "${GREEN}✅ AWS config restored${NC}"
    fi
}

# Docker Backup
backup_docker() {
    echo -e "${BLUE}📦 Backing up Docker credentials...${NC}"
    
    if [ ! -f ~/.docker/config.json ]; then
        echo -e "${YELLOW}⚠️  No ~/.docker/config.json found${NC}"
        return 0
    fi

    local docker_config=$(cat ~/.docker/config.json | base64)
    "$SECRETS_SCRIPT" save "$VAULT" "docker_config" "$docker_config" 2>/dev/null || true
    echo -e "${GREEN}✅ Docker config backed up${NC}"
}

# Docker Restore
restore_docker() {
    echo -e "${BLUE}🔄 Restoring Docker credentials...${NC}"
    
    if "$SECRETS_SCRIPT" get "$VAULT" "docker_config" &>/dev/null; then
        mkdir -p ~/.docker
        local config=$("$SECRETS_SCRIPT" get "$VAULT" "docker_config" | base64 -d)
        echo "$config" > ~/.docker/config.json
        chmod 600 ~/.docker/config.json
        echo -e "${GREEN}✅ Docker config restored${NC}"
    fi
}

# Kubernetes Backup
backup_kube() {
    echo -e "${BLUE}📦 Backing up Kubernetes config...${NC}"
    
    if [ ! -f ~/.kube/config ]; then
        echo -e "${YELLOW}⚠️  No ~/.kube/config found${NC}"
        return 0
    fi

    local kube_config=$(cat ~/.kube/config | base64)
    "$SECRETS_SCRIPT" save "$VAULT" "kube_config" "$kube_config" 2>/dev/null || true
    echo -e "${GREEN}✅ Kube config backed up${NC}"
}

# Kubernetes Restore
restore_kube() {
    echo -e "${BLUE}🔄 Restoring Kubernetes config...${NC}"
    
    if "$SECRETS_SCRIPT" get "$VAULT" "kube_config" &>/dev/null; then
        mkdir -p ~/.kube
        local config=$("$SECRETS_SCRIPT" get "$VAULT" "kube_config" | base64 -d)
        echo "$config" > ~/.kube/config
        chmod 600 ~/.kube/config
        echo -e "${GREEN}✅ Kube config restored${NC}"
    fi
}

# GitHub Backup (gh CLI)
backup_github() {
    echo -e "${BLUE}📦 Backing up GitHub credentials...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠️  GitHub CLI (gh) not installed${NC}"
        echo "Install with: brew install gh"
        return 0
    fi

    if [ ! -f ~/.config/gh/hosts.yml ]; then
        echo -e "${YELLOW}⚠️  GitHub CLI not authenticated. Run: gh auth login${NC}"
        return 0
    fi

    local gh_config=$(cat ~/.config/gh/hosts.yml | base64)
    "$SECRETS_SCRIPT" save "$VAULT" "github_config" "$gh_config" 2>/dev/null || true
    echo -e "${GREEN}✅ GitHub credentials backed up${NC}"
}

# GitHub Restore
restore_github() {
    echo -e "${BLUE}🔄 Restoring GitHub credentials...${NC}"
    
    if ! command -v gh &> /dev/null; then
        echo -e "${YELLOW}⚠️  GitHub CLI (gh) not installed. Install: brew install gh${NC}"
        return 0
    fi

    if "$SECRETS_SCRIPT" get "$VAULT" "github_config" &>/dev/null; then
        mkdir -p ~/.config/gh
        local config=$("$SECRETS_SCRIPT" get "$VAULT" "github_config" | base64 -d)
        echo "$config" > ~/.config/gh/hosts.yml
        chmod 600 ~/.config/gh/hosts.yml
        echo -e "${GREEN}✅ GitHub credentials restored${NC}"
    fi
}

# Git Config Backup
backup_git() {
    echo -e "${BLUE}📦 Backing up Git config...${NC}"
    
    if [ ! -f ~/.gitconfig ]; then
        echo -e "${YELLOW}⚠️  No ~/.gitconfig found${NC}"
        return 0
    fi

    local git_config=$(cat ~/.gitconfig | base64)
    "$SECRETS_SCRIPT" save "$VAULT" "git_config" "$git_config" 2>/dev/null || true
    echo -e "${GREEN}✅ Git config backed up${NC}"
}

# Git Config Restore
restore_git() {
    echo -e "${BLUE}🔄 Restoring Git config...${NC}"
    
    if "$SECRETS_SCRIPT" get "$VAULT" "git_config" &>/dev/null; then
        local config=$("$SECRETS_SCRIPT" get "$VAULT" "git_config" | base64 -d)
        echo "$config" > ~/.gitconfig
        chmod 600 ~/.gitconfig
        echo -e "${GREEN}✅ Git config restored${NC}"
    fi
}

# SSH Keys Backup (backup only for security)
backup_ssh() {
    echo -e "${BLUE}📦 Backing up SSH public keys...${NC}"
    
    if [ ! -d ~/.ssh ]; then
        echo -e "${YELLOW}⚠️  No ~/.ssh directory found${NC}"
        return 0
    fi

    # Only backup public keys (for reference)
    local pub_keys=""
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        pub_keys=$(cat ~/.ssh/id_ed25519.pub | base64)
        "$SECRETS_SCRIPT" save "$VAULT" "ssh_public_key" "$pub_keys" 2>/dev/null || true
        echo -e "${GREEN}✅ SSH public key backed up (reference only)${NC}"
    else
        echo -e "${YELLOW}⚠️  No SSH public key found${NC}"
    fi

    echo -e "${YELLOW}⚠️  NOTE: SSH private keys NOT backed up for security${NC}"
    echo "Keep ~/.ssh/id_ed25519 safe. Restore manually if needed."
}

# SSH Keys Restore
restore_ssh() {
    echo -e "${YELLOW}⚠️  SSH keys require manual restore for security${NC}"
    echo "If you backed up your SSH key securely elsewhere, restore it to ~/.ssh/"
    echo ""
    echo "Usage:"
    echo "  1. Copy your backed-up SSH key to ~/.ssh/id_ed25519"
    echo "  2. chmod 600 ~/.ssh/id_ed25519"
    echo "  3. ssh-add ~/.ssh/id_ed25519"
}

# Show status
show_status() {
    echo -e "${BLUE}📊 Secrets Status${NC}"
    echo ""

    local services=("aws" "docker" "kube" "github" "git" "ssh")
    
    for service in "${services[@]}"; do
        case $service in
            aws)
                check_service "AWS" "~/.aws" "aws_credentials"
                ;;
            docker)
                check_service "Docker" "~/.docker/config.json" "docker_config"
                ;;
            kube)
                check_service "Kubernetes" "~/.kube/config" "kube_config"
                ;;
            github)
                check_service "GitHub CLI" "~/.config/gh/hosts.yml" "github_config"
                ;;
            git)
                check_service "Git Config" "~/.gitconfig" "git_config"
                ;;
            ssh)
                check_ssh_status
                ;;
        esac
    done
}

check_service() {
    local name=$1
    local local_path=$2
    local secret_name=$3
    local resolved_path=${local_path/#\~/$HOME}

    local local_status="❌"
    local stored_status="❌"

    if [ -d "$resolved_path" ] || [ -f "$resolved_path" ]; then
        local_status="✅"
    fi

    if "$SECRETS_SCRIPT" get "$VAULT" "$secret_name" &>/dev/null; then
        stored_status="✅"
    fi

    printf "%-20s Local: %s  Stored: %s\n" "$name" "$local_status" "$stored_status"
}

check_ssh_status() {
    local ssh_key="$HOME/.ssh/id_ed25519"
    local ssh_pub="$HOME/.ssh/id_ed25519.pub"
    local local_status="❌"
    
    if [ -f "$ssh_key" ] && [ -f "$ssh_pub" ]; then
        local_status="✅"
    fi

    local stored_status="⚠️ "  # SSH backup is reference only
    if "$SECRETS_SCRIPT" get "$VAULT" "ssh_public_key" &>/dev/null; then
        stored_status="⚠️  (reference only)"
    fi

    printf "%-20s Local: %s  Stored: %s\n" "SSH Keys" "$local_status" "$stored_status"
}

# Main logic
check_prereqs

service="${2:-all}"

case "$1" in
    backup)
        if [ "$service" = "all" ] || [ -z "$service" ]; then
            echo -e "${BLUE}📦 Backing up all secrets...${NC}\n"
            backup_aws
            backup_docker
            backup_kube
            backup_github
            backup_git
            backup_ssh
        else
            case "$service" in
                aws) backup_aws ;;
                docker) backup_docker ;;
                kube) backup_kube ;;
                github) backup_github ;;
                git) backup_git ;;
                ssh) backup_ssh ;;
                *) echo -e "${RED}❌ Unknown service: $service${NC}"; show_usage; exit 1 ;;
            esac
        fi
        echo -e "${GREEN}✅ Backup complete${NC}"
        ;;
    restore)
        if [ "$service" = "all" ] || [ -z "$service" ]; then
            echo -e "${BLUE}🔄 Restoring all secrets...${NC}\n"
            restore_aws
            restore_docker
            restore_kube
            restore_github
            restore_git
            restore_ssh
        else
            case "$service" in
                aws) restore_aws ;;
                docker) restore_docker ;;
                kube) restore_kube ;;
                github) restore_github ;;
                git) restore_git ;;
                ssh) restore_ssh ;;
                *) echo -e "${RED}❌ Unknown service: $service${NC}"; show_usage; exit 1 ;;
            esac
        fi
        echo -e "${GREEN}✅ Restore complete${NC}"
        ;;
    list)
        if [ "$service" = "all" ] || [ -z "$service" ]; then
            echo -e "${BLUE}📋 All stored secrets:${NC}"
            "$SECRETS_SCRIPT" list "$VAULT"
        else
            echo -e "${BLUE}Secrets for: $service${NC}"
            "$SECRETS_SCRIPT" get "$VAULT" "${service}_config" 2>&1 || echo "Not found"
        fi
        ;;
    status)
        show_status
        ;;
    help|-h|--help)
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
