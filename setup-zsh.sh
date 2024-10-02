#!/bin/bash

# 1. Create ~/.zshenv if it doesn't exist
ZSHENV_PATH="$HOME/.zshenv"
ZDOTDIR_CONFIG="$HOME/.config/zshrc"

if [ -f "$ZSHENV_PATH" ]; then
    echo "$ZSHENV_PATH already exists. Adding ZDOTDIR configuration if necessary."
else
    echo "Creating $ZSHENV_PATH..."
    touch "$ZSHENV_PATH"
fi

# 2. Add ZDOTDIR config to .zshenv
if ! grep -q "export ZDOTDIR=" "$ZSHENV_PATH"; then
    echo "Adding ZDOTDIR configuration to $ZSHENV_PATH"
    echo "export ZDOTDIR=\"$ZDOTDIR_CONFIG\"" >> "$ZSHENV_PATH"
else
    echo "ZDOTDIR configuration already present in $ZSHENV_PATH"
fi

# 3. Create ~/.config/zsh directory if it doesn't exist
if [ ! -d "$ZDOTDIR_CONFIG" ]; then
    echo "Creating $ZDOTDIR_CONFIG directory..."
    mkdir -p "$ZDOTDIR_CONFIG"
fi

# 4. Ensure ~/.config/zsh/zshrc exists
if [ ! -f "$ZDOTDIR_CONFIG/zshrc" ]; then
    echo "No zshrc found in $ZDOTDIR_CONFIG. Creating an empty zshrc file."
    touch "$ZDOTDIR_CONFIG/zshrc"
else
    echo "zshrc already exists in $ZDOTDIR_CONFIG."
fi

# 5. Source the ~/.config/zsh/zshrc in the current session
echo "Sourcing the new ~/.config/zsh/zshrc file..."
source "$ZDOTDIR_CONFIG/zshrc"

# Optional: Notify user to restart terminal or reload shell
echo "Setup complete. You may need to restart your terminal or run 'exec zsh' to apply changes."
