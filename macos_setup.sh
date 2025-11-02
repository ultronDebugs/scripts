#!/bin/bash

# macOS Development Environment Setup Script
# Run with: bash setup.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - Update these with your GitHub username and repo details
GITHUB_USERNAME="your-github-username"
DOTFILES_REPO="dotfiles"  # Your dotfiles repository name
DOTFILES_DIR="$HOME/dotfiles"  # Where to clone the dotfiles

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo_error "This script is intended for macOS only"
    exit 1
fi

echo_info "Starting macOS Development Environment Setup..."
echo ""

# Install Xcode Command Line Tools
echo_info "Installing Xcode Command Line Tools..."
if xcode-select -p &>/dev/null; then
    echo_warn "Xcode Command Line Tools already installed"
else
    xcode-select --install
    echo_warn "Please complete the Xcode Command Line Tools installation and run this script again"
    exit 0
fi

# Install Homebrew
echo_info "Installing Homebrew..."
if command -v brew &>/dev/null; then
    echo_warn "Homebrew already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Update Homebrew
echo_info "Updating Homebrew..."
brew update

# Install essential tools via Homebrew
echo_info "Installing essential tools via Homebrew..."
brew install \
    git \
    curl \
    wget \
    cmatrix \
    cbonsai \
    fastfetch \
    bat \
    eza \
    bpytop \
    fzf \
    ripgrep \
    jq \
    tldr \
    tree

# Install Alacritty
echo_info "Installing Alacritty..."
brew install --cask alacritty

# Install Docker Desktop
echo_info "Installing Docker Desktop..."
brew install --cask docker

# Install NVM (Node Version Manager)
echo_info "Installing NVM..."
if [ -d "$HOME/.nvm" ]; then
    echo_warn "NVM already installed"
else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Node.js via NVM
echo_info "Installing Node.js LTS via NVM..."
source ~/.nvm/nvm.sh
nvm install --lts
nvm use --lts
nvm alias default node

# Install goenv
echo_info "Installing goenv..."
if command -v goenv &>/dev/null; then
    echo_warn "goenv already installed"
else
    brew install goenv
    
    # Add goenv to shell
    echo 'export GOENV_ROOT="$HOME/.goenv"' >> ~/.zshrc
    echo 'export PATH="$GOENV_ROOT/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(goenv init -)"' >> ~/.zshrc
    echo 'export PATH="$GOROOT/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.zshrc
fi

# Install Go via goenv
echo_info "Installing Go via goenv..."
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
LATEST_GO=$(goenv install -l | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
goenv install $LATEST_GO
goenv global $LATEST_GO

# Install Rust
echo_info "Installing Rust..."
if command -v rustc &>/dev/null; then
    echo_warn "Rust already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install Flutter
echo_info "Installing Flutter..."
if command -v flutter &>/dev/null; then
    echo_warn "Flutter already installed"
else
    brew install --cask flutter
fi

# Install Oh My Zsh
echo_info "Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo_warn "Oh My Zsh already installed"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Powerlevel10k
echo_info "Installing Powerlevel10k..."
if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo_warn "Powerlevel10k already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Install zsh plugins
echo_info "Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# Setup Alacritty config
echo_info "Setting up Alacritty configuration..."
mkdir -p ~/.config/alacritty
if [ "$GITHUB_USERNAME" != "your-github-username" ]; then
    echo_info "Cloning Alacritty config from GitHub..."
    git clone "https://github.com/$GITHUB_USERNAME/$ALACRITTY_CONFIG_REPO.git" /tmp/alacritty-config
    cp /tmp/alacritty-config/alacritty.yml ~/.config/alacritty/ 2>/dev/null || \
    cp /tmp/alacritty-config/alacritty.toml ~/.config/alacritty/ 2>/dev/null || \
    echo_warn "Could not find alacritty config file in repo"
    rm -rf /tmp/alacritty-config
else
    echo_warn "Please update GITHUB_USERNAME in the script to clone your Alacritty config"
fi

# Setup zsh config
echo_info "Setting up zsh configuration..."
if [ "$GITHUB_USERNAME" != "your-github-username" ]; then
    echo_info "Cloning zsh config from GitHub..."
    git clone "https://github.com/$GITHUB_USERNAME/$ZSH_CONFIG_REPO.git" /tmp/zsh-config
    
    # Backup existing .zshrc
    if [ -f ~/.zshrc ]; then
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    cp /tmp/zsh-config/.zshrc ~/ 2>/dev/null || echo_warn "Could not find .zshrc in repo"
    cp /tmp/zsh-config/.p10k.zsh ~/ 2>/dev/null || echo_warn "Could not find .p10k.zsh in repo"
    rm -rf /tmp/zsh-config
else
    echo_warn "Please update GITHUB_USERNAME in the script to clone your zsh config"
fi

# Install Nerd Fonts
echo_info "Installing Nerd Fonts..."
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
brew install --cask font-fira-code-nerd-font
brew install --cask font-hack-nerd-font

# Final steps
echo ""
echo_info "==================================="
echo_info "Setup Complete!"
echo_info "==================================="
echo ""
echo_info "Next steps:"
echo "1. Update the script variables (GITHUB_USERNAME, repo names) and run again to pull your configs"
echo "2. Restart your terminal or run: source ~/.zshrc"
echo "3. Configure Powerlevel10k by running: p10k configure"
echo "4. Open Docker Desktop to complete setup"
echo "5. Verify installations:"
echo "   - node --version"
echo "   - go version"
echo "   - rustc --version"
echo "   - flutter --version"
echo ""
echo_info "Installed tools:"
echo "✓ Homebrew"
echo "✓ Xcode Command Line Tools"
echo "✓ Git, curl, wget"
echo "✓ Node.js (via NVM)"
echo "✓ Go (via goenv)"
echo "✓ Rust"
echo "✓ Flutter"
echo "✓ Docker Desktop"
echo "✓ Alacritty"
echo "✓ Oh My Zsh + Powerlevel10k"
echo "✓ cmatrix, cbonsai, fastfetch, bat, eza, bpytop"
echo "✓ fzf, ripgrep, jq, tldr, tree"
echo "✓ Nerd Fonts"
echo ""
