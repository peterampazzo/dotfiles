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
│   ├── install.sh            # Main installation script
│   ├── macos-defaults.sh      # macOS system preferences
│   └── post-install.md        # Manual setup steps
├── configs/                    # Sanitized config templates (examples)
│   ├── zsh/
│   │   └── .zshrc.template
│   └── git/
│       └── .gitconfig.template
├── .gitignore                  # Prevents committing secrets
├── README.md
└── LICENSE
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

## 📝 License

MIT