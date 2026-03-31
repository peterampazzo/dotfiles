# Post-Installation Setup

Manual steps to complete after running `install.sh`.

## 1. Shell Setup

### Install Oh My Zsh
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Configure Zsh Theme
Edit `~/.zshrc` and set:
```bash
ZSH_THEME="robbyrussell"  # or your preferred theme
```

## 2. Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --global core.editor "code"  # or vim, nano, etc.
```

## 3. SSH Keys Setup

If you have existing SSH keys in Google Drive or 1Password:
```bash
# Copy to ~/.ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
```

## 4. Mackup Configuration

### Install Mackup
```bash
brew install mackup
```

### Setup Google Drive Storage

Create `~/.mackup.cfg`:
```ini
[storage]
engine = google_drive

[apps_to_sync]
zsh
git
iterm2
```

### Run Initial Backup
```bash
mackup backup
```

### On New Machine: Restore
```bash
mackup restore
```

## 5. Development Environment

### Node Version Manager (nvm)
```bash
# Add to ~/.zshrc:
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Then restart shell and install Node
nvm install --lts
```

### Python Environment
```bash
# Create virtual environments with venv or poetry
python3 -m venv ~/venv/myproject
source ~/venv/myproject/bin/activate

# Or with poetry
poetry new my-project
```

### Docker
```bash
# Start Docker Desktop or Docker daemon
open -a Docker
```

## 6. IDE Configuration

### VS Code Extensions
All extensions from Brewfile are installed. Additional setup:
- Sign into GitHub Copilot
- Configure linters and formatters
- Set up remote SSH connections if needed

## 7. Browser Setup

### Chrome / Firefox
- Sign in to sync bookmarks and extensions
- Install password manager extension

## 8. Communication Apps

### Slack
- Sign in to workspaces
- Disable auto-launch if not needed

### Telegram / Signal / WhatsApp
- Link to phone account
- Enable notifications

## 9. Install Rosetta 2 (Apple Silicon Only)

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

## 10. Security & SSH Setup (Optional)

### Configure SSH Keys

For more information on SSH security best practices, see:
https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f

## 11. Troubleshooting

### Permission Denied Errors
```bash
chmod +x setup/install.sh
chmod +x setup/macos-defaults.sh
```

### Homebrew Issues
```bash
brew doctor
brew cleanup
brew update
```

### Mackup Issues
```bash
# List what would be synced
mackup list

# Check status
mackup status

# Dry run restore
mackup restore --dry-run
```

## Next Steps

- Customize `.zshrc` with aliases and functions
- Review Brewfile for packages you may not need
- Set up IDE workspace settings
- Configure Git SSH authentication
