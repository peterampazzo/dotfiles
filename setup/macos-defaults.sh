#!/bin/bash

# macOS System Defaults Configuration

echo "⚙️  Configuring macOS defaults..."

# Show hidden files in Finder
defaults write com.apple.Finder AppleShowAllFiles true
killall Finder

# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable mouse acceleration
defaults write .GlobalPreferences com.apple.mouse.scaling -1

# Enable three-finger drag (trackpad)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# Expand save dialog by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Disable .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Dock settings - autohide and minimize to app icon
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock minimize-to-app -bool true

echo "✅ macOS defaults applied"
