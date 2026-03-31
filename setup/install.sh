#!/bin/bash

# Dotfiles Setup Script
# Installs Homebrew packages and runs initial macOS configuration

set -e  # Exit on error

echo "🚀 Starting dotfiles setup..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew already installed"
fi

# Update Homebrew
echo "🔄 Updating Homebrew..."
brew update

# Install from Brewfile
echo "📦 Installing Homebrew packages from Brewfile..."
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
brew bundle --file "$SCRIPT_DIR/../Brewfile"

# Run macOS defaults
if [ -f "$SCRIPT_DIR/macos-defaults.sh" ]; then
    echo "⚙️  Applying macOS defaults..."
    bash "$SCRIPT_DIR/macos-defaults.sh"
fi

echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Install Oh My Zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
echo "  2. Setup Mackup: brew install mackup && mackup backup"
echo "  3. Configure Git: git config --global user.name 'Your Name'"
echo ""
