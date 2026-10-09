#!/usr/bin/env bash

set -Eeuo pipefail

###############################################################################
# mac-agentic-dev-setup
#
# Reproducible bootstrap for a macOS agentic development workstation.
#
# Designed primarily for Apple Silicon Macs.
#
# Safe to rerun:
# - Homebrew installs are idempotent
# - configuration entries are only added when missing
# - existing Git identity is preserved unless changed interactively
###############################################################################

readonly SCRIPT_NAME="$(basename "$0")"

###############################################################################
# Formatting
###############################################################################

if [[ -t 1 ]]; then
    BOLD='\033[1m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    RESET='\033[0m'
else
    BOLD=''
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    RESET=''
fi

info() {
    printf "\n${BLUE}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

success() {
    printf "${GREEN}✓${RESET} %s\n" "$1"
}

warn() {
    printf "${YELLOW}!${RESET} %s\n" "$1"
}

error() {
    printf "${RED}ERROR:${RESET} %s\n" "$1" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

append_line_if_missing() {
    local line="$1"
    local file="$2"

    touch "$file"

    if ! grep -Fqx "$line" "$file" 2>/dev/null; then
        printf '\n%s\n' "$line" >> "$file"
    fi
}

###############################################################################
# Preconditions
###############################################################################

info "Checking operating system"

if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This setup script supports macOS only."
    exit 1
fi

ARCH="$(uname -m)"

echo "Architecture: $ARCH"

if [[ "$ARCH" == "arm64" ]]; then
    success "Apple Silicon detected"
else
    warn "Intel Mac detected. The script should mostly work, but Apple Silicon is the target configuration."
fi

sw_vers

###############################################################################
# FileVault
###############################################################################

info "Checking FileVault"

if command_exists fdesetup; then
    FILEVAULT_STATUS="$(fdesetup status 2>/dev/null || true)"

    echo "$FILEVAULT_STATUS"

    if echo "$FILEVAULT_STATUS" | grep -qi "FileVault is On"; then
        success "FileVault is enabled"
    else
        warn "FileVault is not enabled."
        warn "Enable it in System Settings -> Privacy & Security -> FileVault."
    fi
fi

###############################################################################
# Xcode Command Line Tools
###############################################################################

info "Checking Apple Command Line Tools"

if ! xcode-select -p >/dev/null 2>&1; then
    warn "Apple Command Line Tools are not installed."
    echo
    echo "macOS will now open the Command Line Tools installer."
    echo "Complete the installation, then rerun:"
    echo
    echo "    ./$SCRIPT_NAME"
    echo

    xcode-select --install || true
    exit 0
fi

success "Apple Command Line Tools installed"

###############################################################################
# Homebrew
###############################################################################

info "Checking Homebrew"

if ! command_exists brew; then
    echo "Installing Homebrew..."

    /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Homebrew lives here on Apple Silicon.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"

    append_line_if_missing \
        'eval "$(/opt/homebrew/bin/brew shellenv)"' \
        "$HOME/.zprofile"

# Intel Homebrew.
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"

    append_line_if_missing \
        'eval "$(/usr/local/bin/brew shellenv)"' \
        "$HOME/.zprofile"
fi

if ! command_exists brew; then
    error "Homebrew installation failed."
    exit 1
fi

success "Homebrew available: $(brew --version | head -1)"

###############################################################################
# Update Homebrew metadata
###############################################################################

info "Updating Homebrew"

brew update

###############################################################################
# Core command-line utilities
###############################################################################

info "Installing command-line development tools"

BREW_FORMULAE=(
    git
    gh

    jq
    yq

    ripgrep
    fd
    fzf
    bat
    eza
    tree

    wget
    curl

    htop
    tmux
    direnv

    starship

    mise
    uv

    kubectl
    helm
    k9s
    kind

    shellcheck
    shfmt
    pre-commit
    gitleaks
    actionlint
    hadolint
)

for formula in "${BREW_FORMULAE[@]}"; do
    if brew list --formula "$formula" >/dev/null 2>&1; then
        success "$formula already installed"
    else
        echo "Installing $formula..."
        brew install "$formula"
    fi
done

###############################################################################
# Desktop applications
###############################################################################

info "Installing desktop development applications"

declare -A BREW_CASKS=(
    [ghostty]="Ghostty.app"
    [visual-studio-code]="Visual Studio Code.app"
    [cursor]="Cursor.app"
    [chatgpt]="ChatGPT.app"
    [orbstack]="OrbStack.app"
)

for cask in "${!BREW_CASKS[@]}"; do
    app_name="${BREW_CASKS[$cask]}"
    app_path="/Applications/$app_name"

    # Already managed by Homebrew
    if brew list --cask "$cask" >/dev/null 2>&1; then
        success "$cask already installed and managed by Homebrew"
        continue
    fi

    # Application exists but was installed outside Homebrew
    if [[ -d "$app_path" ]]; then
        echo "$app_name already exists in /Applications."
        echo "Attempting to adopt it into Homebrew..."

        if brew install --cask --adopt "$cask"; then
            success "$cask adopted by Homebrew"
        else
            warn "Could not adopt $app_name."
            warn "Leaving the existing application untouched."
        fi

        continue
    fi

    # Normal fresh installation
    echo "Installing $cask..."
    brew install --cask "$cask"
done

###############################################################################
# Cursor CLI
###############################################################################

info "Installing Cursor CLI"

if brew info --cask cursor-cli >/dev/null 2>&1; then
    if brew list --cask cursor-cli >/dev/null 2>&1; then
        success "Cursor CLI already installed"
    else
        brew install --cask cursor-cli
    fi
else
    warn "Cursor CLI Homebrew cask was not found. Skipping."
fi

###############################################################################
# Shell configuration
###############################################################################

info "Configuring zsh"

touch "$HOME/.zshrc"
touch "$HOME/.zprofile"

append_line_if_missing \
    'eval "$(starship init zsh)"' \
    "$HOME/.zshrc"

append_line_if_missing \
    'eval "$(mise activate zsh)"' \
    "$HOME/.zshrc"

append_line_if_missing \
    'eval "$(direnv hook zsh)"' \
    "$HOME/.zshrc"

append_line_if_missing \
    'export PATH="$HOME/.local/bin:$PATH"' \
    "$HOME/.zshrc"

success "zsh configured"

###############################################################################
# Load mise into current bootstrap process
###############################################################################

eval "$(mise activate bash)"

###############################################################################
# Runtime management
###############################################################################

info "Installing development runtimes with mise"

mise use --global node@lts
mise use --global python@3.13
mise use --global java@21
mise use --global go@latest

success "Runtime installation complete"

###############################################################################
# Corepack
###############################################################################

info "Enabling Corepack"

if command_exists corepack; then
    corepack enable
    success "Corepack enabled"
else
    warn "corepack was not found after Node installation"
fi

###############################################################################
# Git configuration
###############################################################################

info "Configuring Git"

git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global fetch.prune true
git config --global rerere.enabled true
git config --global rerere.autoupdate true
git config --global push.autoSetupRemote true
git config --global worktree.guessRemote true

# Modern diff behaviour.
git config --global diff.algorithm histogram
git config --global merge.conflictstyle zdiff3

# Helpful colour support.
git config --global color.ui auto

###############################################################################
# Git identity
###############################################################################

CURRENT_NAME="$(git config --global user.name || true)"
CURRENT_EMAIL="$(git config --global user.email || true)"

echo
echo "Current Git identity:"
echo "  Name : ${CURRENT_NAME:-<not configured>}"
echo "  Email: ${CURRENT_EMAIL:-<not configured>}"
echo

read -r -p "Configure/update Git identity now? [y/N] " configure_git

if [[ "$configure_git" =~ ^[Yy]$ ]]; then

    read -r -p "Git user.name: " git_name
    read -r -p "Git user.email: " git_email

    if [[ -n "$git_name" ]]; then
        git config --global user.name "$git_name"
    fi

    if [[ -n "$git_email" ]]; then
        git config --global user.email "$git_email"
    fi

    success "Git identity configured"
fi

###############################################################################
# Global Git ignore
###############################################################################

info "Configuring global Git exclusions"

GLOBAL_GITIGNORE="$HOME/.gitignore_global"

touch "$GLOBAL_GITIGNORE"

GLOBAL_IGNORE_PATTERNS=(
    ".DS_Store"
    ".env"
    ".env.local"
    ".env.*.local"
    "*.pem"
    "*.key"
)

for pattern in "${GLOBAL_IGNORE_PATTERNS[@]}"; do
    if ! grep -Fqx "$pattern" "$GLOBAL_GITIGNORE"; then
        echo "$pattern" >> "$GLOBAL_GITIGNORE"
    fi
done

git config --global core.excludesfile "$GLOBAL_GITIGNORE"

success "Global Git exclusions configured"

###############################################################################
# Useful Git aliases
###############################################################################

info "Configuring useful Git aliases"

git config --global alias.st "status --short --branch"
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg \
    "log --graph --decorate --oneline --all"

success "Git aliases configured"

###############################################################################
# Codex CLI
###############################################################################

info "Installing OpenAI Codex CLI"

if command_exists codex; then
    success "Codex already installed: $(codex --version 2>/dev/null || echo installed)"
else
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

###############################################################################
# Claude Code
###############################################################################

info "Installing Claude Code"

if command_exists claude; then
    success "Claude Code already installed: $(claude --version 2>/dev/null || echo installed)"
else
    curl -fsSL https://claude.ai/install.sh | bash
fi

###############################################################################
# Refresh PATH
###############################################################################

export PATH="$HOME/.local/bin:$PATH"

###############################################################################
# Jupyter
###############################################################################

info "Installing Jupyter"

if uv tool list | grep -Eq '^jupyterlab([[:space:]]|$)'; then
    success "JupyterLab already installed"
else
    echo "Installing JupyterLab and Jupyter Notebook..."
    uv tool install \
        --python "$(mise which python)" \
        jupyterlab \
        --with notebook \
        --with pip \
        --with-executables-from jupyter-core \
        --with-executables-from notebook
    success "Jupyter installed"
fi

###############################################################################
# OrbStack
###############################################################################

info "Initializing OrbStack"

if [[ -d "/Applications/OrbStack.app" ]]; then
    open -a OrbStack || true

    echo
    echo "OrbStack may display a first-run configuration dialog."
    echo "Complete that dialog if macOS presents one."
else
    warn "OrbStack application was not found."
fi

###############################################################################
# GitHub authentication
###############################################################################

info "Checking GitHub CLI authentication"

if gh auth status >/dev/null 2>&1; then
    success "GitHub CLI is already authenticated"
else
    echo
    read -r -p "Authenticate GitHub CLI now? [Y/n] " auth_github

    auth_github="${auth_github:-Y}"

    if [[ "$auth_github" =~ ^[Yy]$ ]]; then
        gh auth login
    else
        warn "Skipping GitHub authentication."
        echo "Later run:"
        echo
        echo "    gh auth login"
    fi
fi

###############################################################################
# Homebrew health
###############################################################################

info "Running Homebrew diagnostics"

brew doctor || true

###############################################################################
# Verification
###############################################################################

info "Verifying installation"

verify_command() {
    local command_name="$1"

    if command_exists "$command_name"; then
        printf "${GREEN}%-18s${RESET} %s\n" \
            "$command_name" \
            "$(command -v "$command_name")"
    else
        printf "${RED}%-18s${RESET} %s\n" \
            "$command_name" \
            "NOT FOUND"
    fi
}

TOOLS=(
    brew
    git
    gh

    jq
    yq
    rg
    fd
    fzf
    bat
    eza
    tree

    curl
    wget

    tmux
    direnv
    starship

    mise
    uv

    node
    npm
    python
    jupyter
    java
    go

    kubectl
    helm
    k9s
    kind

    shellcheck
    shfmt
    pre-commit
    gitleaks
    actionlint
    hadolint

    code
    cursor

    codex
    claude
)

for tool in "${TOOLS[@]}"; do
    verify_command "$tool"
done

###############################################################################
# Runtime versions
###############################################################################

info "Installed runtime versions"

echo
node --version 2>/dev/null || true
npm --version 2>/dev/null || true
python --version 2>/dev/null || true
jupyter --version 2>/dev/null || true
java --version 2>/dev/null || true
go version 2>/dev/null || true
uv --version 2>/dev/null || true

###############################################################################
# Claude diagnostics
###############################################################################

if command_exists claude; then
    info "Claude Code diagnostics"
    claude doctor || true
fi

###############################################################################
# Docker / OrbStack verification
###############################################################################

info "Checking container runtime"

# Give OrbStack a short opportunity to initialize.
for _ in {1..15}; do
    if docker info >/dev/null 2>&1; then
        break
    fi

    sleep 1
done

if command_exists docker; then
    docker --version || true

    if docker info >/dev/null 2>&1; then
        success "Docker-compatible runtime is running"

        echo
        echo "Running hello-world container..."

        docker run --rm hello-world || true
    else
        warn "Docker CLI is installed but the OrbStack runtime is not ready."
        warn "Open OrbStack and complete its first-run setup."
    fi
else
    warn "Docker CLI not yet available."
    warn "Open OrbStack once to complete installation."
fi

###############################################################################
# Git configuration summary
###############################################################################

info "Git configuration"

echo
echo "user.name:          $(git config --global user.name || echo '<not configured>')"
echo "user.email:         $(git config --global user.email || echo '<not configured>')"
echo "default branch:     $(git config --global init.defaultBranch)"
echo "pull.rebase:        $(git config --global pull.rebase)"
echo "fetch.prune:        $(git config --global fetch.prune)"
echo "rerere:             $(git config --global rerere.enabled)"
echo "auto setup remote:  $(git config --global push.autoSetupRemote)"
echo "global gitignore:   $(git config --global core.excludesfile)"

###############################################################################
# GitHub status
###############################################################################

info "GitHub CLI status"

gh auth status || true

###############################################################################
# Final instructions
###############################################################################

echo
echo "======================================================================"
echo " Setup complete"
echo "======================================================================"
echo
echo "Installed/configured:"
echo
echo "  Terminal"
echo "    Ghostty"
echo "    zsh"
echo "    Starship"
echo "    tmux"
echo
echo "  Source control"
echo "    Git"
echo "    GitHub CLI"
echo
echo "  Runtime management"
echo "    mise"
echo "    Node LTS"
echo "    Python 3.13"
echo "    Java 21"
echo "    Go"
echo "    uv"
echo "    JupyterLab"
echo "    Jupyter Notebook"
echo
echo "  Editors"
echo "    Visual Studio Code"
echo "    Cursor"
echo
echo "  AI development"
echo "    ChatGPT desktop"
echo "    OpenAI Codex CLI"
echo "    Claude Code"
echo "    Cursor CLI"
echo
echo "  Containers"
echo "    OrbStack"
echo "    Docker-compatible CLI/runtime"
echo
echo "  Kubernetes"
echo "    kubectl"
echo "    Helm"
echo "    k9s"
echo "    kind"
echo
echo "  Quality/security"
echo "    ShellCheck"
echo "    shfmt"
echo "    pre-commit"
echo "    gitleaks"
echo "    actionlint"
echo "    hadolint"
echo
echo "IMPORTANT:"
echo
echo "Open a NEW terminal window before doing further work."
echo
echo "Then authenticate tools that require interactive login:"
echo
echo "    claude"
echo "    codex"
echo
echo "Cursor and ChatGPT should be launched once from Applications"
echo "and authenticated interactively."
echo
echo "OrbStack should also be opened once to finish its first-run setup."
echo
echo "======================================================================"