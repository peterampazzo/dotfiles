# Dotfiles ⚙️

Automated macOS development environment setup with Homebrew and curated configurations.

## 📋 What's Included

- **Brewfile** — Homebrew packages, casks, and VS Code extensions
- **Setup scripts** — Automated installation and configuration
- **Configuration templates** — Sanitized config examples

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/[your-username]/dotfiles.git
cd dotfiles
```

### 2. Run Setup
```bash
chmod +x setup/install.sh
./setup/install.sh
```

### 3. Install Homebrew Packages
```bash
brew bundle --file ./Brewfile
```

## 🔧 What Gets Installed

### Homebrew Packages
- **Development**: node, python@3.11, docker, dotnet, terraform, poetry
- **Tools**: ffmpeg, imagemagick, tesseract, wget, yt-dlp, tree
- **Utilities**: openssl@3, protobuf, freetds, vips

### Applications (Casks)
- **Productivity**: 1Password, Slack, Microsoft Teams, Spotify, Telegram
- **Development**: Visual Studio Code, Postman, Docker, iTerm2
- **Media**: VLC, Darktable, LibreOffice
- **Communication**: Signal, WhatsApp, Zoom, Firefox, Chrome

### VS Code Extensions
- **Language Support**: Python, Java, C++, YAML, LaTeX
- **Tools**: GitLens, ESLint, Prettier, Terraform, Docker
- **AI**: GitHub Copilot, Copilot Chat
- **Productivity**: Jupyter, Database Client, Rainbow CSV

## 📦 Managing Configs with Mackup

### Setup Mackup with Google Drive (Safe)

1. **Install mackup**:
   ```bash
   brew install mackup
   ```

2. **Configure for Google Drive** (create `~/.mackup.cfg`):
   ```ini
   [storage]
   engine = google_drive

   [apps_to_sync]
   zsh
   git
   iterm2
   ```

3. **First sync to Google Drive**:
   ```bash
   mackup backup
   ```

4. **Restore on new machine**:
   ```bash
   mackup restore
   ```

### What Mackup Backs Up (to Google Drive)
- iTerm2 profiles and preferences
- Zsh configuration (.zshrc)
- Git configuration
- SSH keys (optionally, stored securely in Google Drive)

### ⚠️ Important Security Notes
- **Never commit actual configs to this repo** — configs contain machine-specific data
- **Google Drive is encrypted in transit** — recommended for selective app configs
- **This repo stays public and safe** — only package info, no credentials
- **Use `.mackupignore`** to exclude sensitive apps:
  ```
  1Password
  aws
  azure
  slack
  ```

## 🔄 Updating Brewfile

To update the Brewfile with your current installed packages:
```bash
brew bundle dump --file ./Brewfile --force
```

## 📂 Project Structure

```
dotfiles/
├── Brewfile                    # Homebrew packages & casks
├── setup/
│   ├── install.sh              # Main installation script
│   ├── macos-defaults.sh       # macOS system preferences
│   └── post-install.md         # Manual setup steps
├── scripts/
│   ├── secrets-sync.sh         # Unified secrets backup/restore
│   ├── secrets.sh              # 1Password secret storage helpers
│   ├── git-setup.sh            # SSH key setup
│   └── load-secrets.sh         # Auto-load credentials into shell
├── mackup-backup/              # Mackup-managed app configs
├── .gitignore                  # Prevents committing secrets
└── README.md
```

## 🛠️ Manual Setup Steps

After running scripts, you may need to:

1. **Install Oh My Zsh**:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

2. **Enable hidden files in Finder**:
   ```bash
   defaults write com.apple.Finder AppleShowAllFiles true
   killall Finder
   ```

3. **Install Rosetta 2** (for Apple Silicon):
   ```bash
   /usr/sbin/softwareupdate --install-rosetta --agree-to-license
   ```

4. **Configure Git credentials**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

## 🔐 Security Best Practices

- ✅ **Brewfile** — safe, publicly visible
- ✅ **Setup scripts** — safe, publicly visible
- ❌ **Credentials** — never commit (use 1Password or similar)
- ❌ **SSH keys** — keep in ~/.ssh (or sync to Google Drive via Mackup only)
- ❌ **API tokens** — use environment variables or secure storage
## 🐙 Git & GitHub Setup

One-command setup: authenticates with GitHub, generates an SSH key, enables signed commits, and backs up to 1Password.

```bash
./scripts/git-setup.sh setup
```

This runs 5 steps:
1. **GitHub CLI auth** — logs in via `gh` with SSH protocol
2. **SSH key** — generates Ed25519 key (or reuses existing)
3. **GitHub upload** — adds key as both authentication and signing key
4. **Commit signing** — configures git to sign all commits/tags with SSH
5. **1Password backup** — stores public key in the `dev` vault

### Verify

```bash
./scripts/git-setup.sh status   # show config
./scripts/git-setup.sh test     # test SSH + signed commit
```

### What gets configured

| Setting | Value |
|---------|-------|
| Protocol | SSH |
| Signing format | SSH (no GPG/certs needed) |
| Auto-sign | commits + tags |
| Key | `~/.ssh/id_ed25519` |
| Allowed signers | `~/.ssh/allowed_signers` |

### Backup & restore

```bash
# Backup GitHub + git config to 1Password
./scripts/secrets-sync.sh backup github
./scripts/secrets-sync.sh backup git

# Restore on new machine
./scripts/secrets-sync.sh restore github
./scripts/secrets-sync.sh restore git
```
## � Managing Credentials with 1Password

This repo includes scripts to securely manage credentials using 1Password CLI.

### Setup

1. **Install 1Password CLI**:
   ```bash
   brew install 1password-cli
   op account add  # Sign in
   ```

2. **Create a vault for secrets**:
   ```bash
   ./scripts/secrets.sh create-vault Private
   ```

### Usage

**Save a credential:**
```bash
./scripts/secrets.sh save Private slack_token "xoxb-xxxxx"
./scripts/secrets.sh save Private github_token "ghp_xxxxx"
```

**Retrieve a credential:**
```bash
./scripts/secrets.sh get Private slack_token
```

**List all secrets in a vault:**
```bash
./scripts/secrets.sh list Private
```

**Load credentials in your shell** (add to `~/.zshrc`):
```bash
# Manual load:
export GITHUB_TOKEN="$(./scripts/secrets.sh get Private github_token)"

# Or edit scripts/load-secrets.sh and source it:
eval "$(~/GitHub/dotfiles/scripts/load-secrets.sh)"
```

**Export for use in scripts:**
```bash
eval "$(./scripts/secrets.sh export Private DATABASE_URL db_password)"
echo $DATABASE_URL
```

### What Goes Where

| Config | Storage | Mackup? | secrets-sync? | Git tracked? |
|--------|---------|---------|---------------|--------------|
| .zshrc | Local | ✅ Google Drive | ❌ | ❌ |
| .gitconfig | Local | ❌ | ✅ 1Password | ❌ |
| iTerm2 prefs | Local | ✅ Google Drive | ❌ | ❌ |
| AWS creds | ~/.aws | ❌ | ✅ 1Password | ❌ |
| Docker creds | ~/.docker | ❌ | ✅ 1Password | ❌ |
| Kube config | ~/.kube | ❌ | ✅ 1Password | ❌ |
| GitHub token | ~/.config/gh | ❌ | ✅ 1Password | ❌ |
| SSH keys | ~/.ssh | ❌ | ⚠️ Ref only | ❌ |

**Never commit:** API keys, database credentials, SSH keys, tokens, registry passwords, or cloud credentials.

### Useful Commands

```bash
# Help
./scripts/secrets.sh help

# Create production vault (caution!)
./scripts/secrets.sh create-vault prod

# List all vaults and secrets
op vault list
op item list --vault Private

# Securely delete a secret
op item delete secret_name --vault Private
```

For more info: https://1password.com/devs/
