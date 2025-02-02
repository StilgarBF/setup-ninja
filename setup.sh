#!/bin/bash

# Exit on errors
set -e

# Update and install dependencies
echo "Updating package list..."
sudo apt update -y
sudo apt upgrade -y

echo "Installing necessary tools..."
sudo apt install -y zsh git curl wget fzf build-essential

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    # set default shell to zsh
    echo "Changing default shell to zsh (you may need to enter your password)..."
    chsh -s $(which zsh) || echo "Run 'chsh -s $(which zsh)' manually if needed."
fi

# Install Powerline Fonts for Agnoster Theme
if [ ! -d "$HOME/.local/share/fonts" ]; then
    echo "Installing Powerline fonts..."
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    ./install.sh
    cd ..
    rm -rf fonts
fi

# Set Zsh theme to Agnoster
echo "Configuring Zsh..."
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc

# Install Atuin for shell history
if ! command -v atuin &> /dev/null; then
    echo "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
fi

# Install Ghostty
if ! command -v ghostty &> /dev/null; then
    echo "Installing Ghostty..."
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
fi

# Add or update the Ghostty theme setting
CONFIG_FILE="$HOME/.config/ghostty"

if grep -q "^theme = " "$CONFIG_FILE"; then
    # Update the existing theme setting
    sed -i 's/^theme = .*/theme = Monokai Classic/' "$CONFIG_FILE"
else
    # Add the theme setting if it doesn't exist
    echo "theme = Monokai Classic" >> "$CONFIG_FILE"
fi

# Install Superfile
if ! command -v superfile &> /dev/null; then
    echo "Installing Superfile..."
    bash -c "$(curl -sLo- https://superfile.netlify.app/install.sh)"
fi

# Install glances (Alternative to htop)
if ! command -v glances &> /dev/null; then
    echo "Installing glances..."
    sudo apt install glances -y
    echo "alias htop='glances'" >> ~/.zshrc
fi

# Install Lazygit
if ! command -v lazygit &> /dev/null; then
    echo "Installing Lazygit..."
    LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    curl -Lo lazygit.tar.gz https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz
    tar xzf lazygit.tar.gz lazygit
    sudo mv lazygit /usr/local/bin/
    rm -f lazygit.tar.gz
fi

# Apply changes
echo "Applying changes..."
zsh -c "source ~/.zshrc"

echo "Setup complete! Restart your shell to apply changes."
