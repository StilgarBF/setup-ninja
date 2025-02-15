#!/bin/bash

# Exit on errors
set -e

# Detect terminal color support
if [[ "$COLORTERM" == "truecolor" ]] || [[ "$COLORTERM" == "24bit" ]]; then
    # True color (24-bit)
    RED='\e[38;2;255;0;0m'
    GREEN='\e[38;2;0;255;0m'
    YELLOW='\e[38;2;255;255;0m'
    BLUE='\e[38;2;0;0;255m'
    CYAN='\e[38;2;0;255;255m'
    BOLD='\e[1m'
    RESET='\e[0m'
elif [[ "$(tput colors)" -ge 256 ]]; then
    # 256 color fallback
    RED='\e[31m'
    GREEN='\e[32m'
    YELLOW='\e[33m'
    RESET='\e[0m'
else
    # Standard Linux terminal (basic colors)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
fi

# Update and install dependencies
printf "${GREEN}Updating package list...${RESET}\n"
sudo apt update -y
sudo apt upgrade -y

printf "${GREEN}Installing necessary tools...${RESET}\n"
sudo apt install -y zsh git curl wget fzf build-essential

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    printf "${GREEN}Installing Oh My Zsh...${RESET}\n"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # set default shell to zsh
    printf "${GREEN}Changing default shell to zsh (you may need to enter your password)...${RESET}\n"
    chsh -s $(which zsh) || printf "${YELLOW}Run 'chsh -s $(which zsh)' manually if needed.${RESET}\n"
fi

# Install Powerline Fonts for Agnoster Theme
if [ ! -d "$HOME/.local/share/fonts" ]; then
    printf "${GREEN}Installing Powerline fonts...${RESET}\n"
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    ./install.sh
    cd ..
    rm -rf fonts
fi

# Set Zsh theme to Agnoster
printf "${GREEN}Configuring Zsh...${RESET}\n"
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc

# Install Atuin for shell history
if ! command -v atuin &> /dev/null; then
    printf "${GREEN}Installing Atuin...${RESET}\n"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
fi

# Install Ghostty
if ! command -v ghostty &> /dev/null; then
    printf "${GREEN}Installing Ghostty...${RESET}\n"
    source /etc/os-release
    ARCH=$(dpkg --print-architecture)
    GHOSTTY_DEB_URL=$(
    curl -s https://api.github.com/repos/mkasberg/ghostty-ubuntu/releases/latest | \
    grep -oP "https://github.com/mkasberg/ghostty-ubuntu/releases/download/[^\s/]+/ghostty_[^\s/_]+_${ARCH}_${VERSION_ID}.deb"
    )
    GHOSTTY_DEB_FILE=$(basename "$GHOSTTY_DEB_URL")
    curl -LO "$GHOSTTY_DEB_URL"
    sudo dpkg -i "$GHOSTTY_DEB_FILE"
    rm "$GHOSTTY_DEB_FILE"
    # install missing dependencies - just to be sure
    sudo apt install -f -y
fi

# Add or update the Ghostty theme setting
CONFIG_FILE="$HOME/.config/ghostty"

if grep -q "^theme = " "$CONFIG_FILE"; then
    # Update the existing theme setting
    sed -i 's/^theme = .*/theme = Monokai Classic/' "$CONFIG_FILE"
else
    # Add the theme setting if it doesn't exist
    printf "theme = Monokai Classic" >> "$CONFIG_FILE\n"
fi

# Install Superfile
if ! command -v superfile &> /dev/null; then
    printf "${GREEN}Installing Superfile...${RESET}\n"
    bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
fi

# Install glances (Alternative to htop)
if ! command -v glances &> /dev/null; then
    printf "${GREEN}Installing glances...${RESET}\n"
    sudo apt install glances -y
    echo "alias htop='glances'" >> ~/.zshrc
fi

# Install Lazygit
if ! command -v lazygit &> /dev/null; then
    printf "${GREEN}Installing Lazygit...${RESET}\n"
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    curl -Lo lazygit.tar.gz https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz
    tar xzf lazygit.tar.gz lazygit
    sudo mv lazygit /usr/local/bin/
    rm -f lazygit.tar.gz
fi

# Apply changes
printf "${GREEN}Applying changes...${RESET}\n"
zsh -c "source ~/.zshrc"

printf "${GREEN}Setup complete! Restart your shell to apply changes.${RESET}\n"
printf "${YELLOW}You may have to run \"echo 'eval \"\$(atuin init zsh)\"' >> ~/.zshrc\" in ghostty manually again.${RESET}\n"
