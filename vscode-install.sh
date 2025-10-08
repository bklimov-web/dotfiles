echo "🧩 Setting up VS Code configuration..."

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
BACKUP_DIR="$HOME/vscode_backup_$(date +%Y%m%d_%H%M%S)"

FILES_TO_CLEAN=(
  "$VSCODE_USER_DIR/settings.json"
  "$VSCODE_USER_DIR/keybindings.json"
  "$VSCODE_USER_DIR/snippets"
)

# 1️⃣ Очистка старых файлов
for file in "${FILES_TO_CLEAN[@]}"; do
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    echo "⚠️  Found existing file: $file"
    echo "   Moving to backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mv "$file" "$BACKUP_DIR/"
  fi
done

# 2️⃣ Создание симлинков
echo "🔗 Linking VS Code config files..."
stow --restow vscode

# 3️⃣ Установка расширений
if command -v code &>/dev/null && [ -f ~/dotfiles/vscode/extensions.txt ]; then
  echo "📦 Installing VS Code extensions..."
  installed=$(code --list-extensions)
  while IFS= read -r ext; do
    if echo "$installed" | grep -q "$ext"; then
      echo "✅ $ext already installed"
    else
      echo "⬇️  Installing $ext..."
      code --install-extension "$ext" --force || echo "⚠️  Failed to install $ext"
      sleep 0.3
    fi
  done < ~/dotfiles/vscode/extensions.txt
else
  echo "⚠️  VS Code CLI not found or extensions.txt missing"
fi

echo "✅ VS Code setup complete!"

