#!/bin/bash

install_gcm() {
    # Check if GCM is already installed
    if ! command -v git-credential-manager &>/dev/null; then
        echo "[*] Installing Git Credential Manager..."
        local gcmVer="2.6.1"
        wget https://github.com/GitCredentialManager/git-credential-manager/releases/latest/download/gcm-linux_amd64.${gcmVer}.deb
        sudo dpkg -i "gcm-linux_amd64.${gcmVer}.deb"
    else
        echo "[*] Git Credential Manager already installed."
    fi
}

configure_git_gcm() {
    # Set Git to use GCM if not already set
    CURRENT_HELPER=$(git config --global credential.helper || echo "")
    if [[ "$CURRENT_HELPER" != *git-credential-manager* ]]; then
        GCM_PATH=$(command -v git-credential-manager)
        echo "[*] Configuring Git to use GCM at: $GCM_PATH"
        git config --global credential.helper "$GCM_PATH"
    else
        echo "[*] Git already configured to use GCM."
    fi
}

detect_windows_browser() {
    local browser_path=""
    # Detect preferred Windows browser
    # if [ -x "/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" ]; then
    #     browser_path="/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
    # elif [ -x "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" ]; then
    #     browser_path="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
    # else
        browser_path="/mnt/c/Windows/explorer.exe"
#    fi
    echo "$browser_path"
}

write_env_config() {
    local env_file="$1"
    local browser_path="$2"
    
    echo "[*] Writing environment configuration to $env_file"
    cat >"$env_file" <<EOF
# Environment for Git Credential Manager in WSL
export GCM_CREDENTIAL_STORE=cache
export BROWSER="$browser_path"
EOF
}

update_bashrc() {
    local env_file="$1"
    
    # Ensure it's sourced from .bashrc (idempotently)
    if ! grep -q "$env_file" "$HOME/.bashrc"; then
        echo "source \"$env_file\"" >>"$HOME/.bashrc"
        echo "[*] Added source line to ~/.bashrc"
    else
        echo "[*] ~/.bashrc already sourcing $env_file"
    fi
}

main() {
    local env_file="$1"
    echo "[*] Setting up GitHub authentication in WSL..."

    install_gcm
    configure_git_gcm
    local browser_path=$(detect_windows_browser)
    write_env_config "$env_file" "$browser_path"
    update_bashrc "$env_file"

    echo "[✓] Setup complete. Restart your shell or run: source \"$env_file\""
}

if [[ -z ${sourceMe:-} ]]; then
    set -euo pipefail

    # Name of the file to hold environment variables
    ENV_FILE="$HOME/gcm-wsl-env.bashrc"
    main "$ENV_FILE"
fi
