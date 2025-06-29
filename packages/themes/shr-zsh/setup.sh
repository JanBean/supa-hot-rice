load_setup() {
    # Change shell to zsh
    echo ":: !!!!!!!!!! Changing Shell to Zsh. !!!!!!!!!!"

    while ! chsh -s $(which zsh); do
        echo "ERROR: Authentication failed. Please enter the correct password."
        sleep 1
    done
    echo ":: Shell is now zsh."

    # install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Installing zsh-autosuggestions
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        echo ":: Installing zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    else
        echo ":: zsh-autosuggestions already installed"
    fi

    echo ":: Select your font by calling: oh-my-posh font install "
    # im using Hack
}

unload_setup() {
    echo ":: !!!!!!!!!!!!!!! Uninstalling custom Zsh setup... !!!!!!!!!!!!!!!!!!"

    # Revert shell to Bash if current shell is Zsh
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"
    if [[ "$current_shell" == *zsh ]]; then
        echo ":: Changing shell back to Bash..."
        chsh -s /bin/bash "$USER"
    fi

    # Remove oh-my-zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo ":: Removing Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
    fi

    # Remove .zshrc and stow links (assuming they point to your custom config)
    if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
        echo ":: Removing .zshrc file..."
        rm -f "$HOME/.zshrc"
    fi

    # Optionally remove any stowed configs under ~/ (dangerous if shared!)
    if command -v stow >/dev/null && [ -d "$HOME/zsh" ]; then
        echo ":: Unstowing zsh config (if applicable)..."
        stow -D zsh -t "$HOME"
    fi

    # Remove autosuggestions plugin if still there
    zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ -d "$zsh_custom_dir/plugins/zsh-autosuggestions" ]; then
        echo ":: Removing zsh-autosuggestions plugin..."
        rm -rf "$zsh_custom_dir/plugins/zsh-autosuggestions"
    fi

    echo ":: Zsh config cleanup complete."
}