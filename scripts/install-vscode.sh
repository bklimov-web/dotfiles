#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
(cd "$DOTFILES" && stow --restow vscode)

# 3️⃣ Установка расширений: общий слой + слой профиля
PROFILE="${1:-${MACHINE_PROFILE:-}}"
EXT_FILES=("$DOTFILES/vscode/extensions.txt")
if [ -n "$PROFILE" ]; then
  EXT_FILES+=("$DOTFILES/vscode/extensions.$PROFILE.txt")
fi

if command -v code &>/dev/null; then
  echo "📦 Installing VS Code extensions (profile: ${PROFILE:-none})..."
  installed=$(code --list-extensions)
  for file in "${EXT_FILES[@]}"; do
    [ -f "$file" ] || { echo "⚠️  $file not found, skipping"; continue; }
    while IFS= read -r ext; do
      [[ -z "$ext" || "$ext" == \#* ]] && continue
      if echo "$installed" | grep -qix "$ext"; then
        echo "✅ $ext already installed"
      else
        echo "⬇️  Installing $ext..."
        code --install-extension "$ext" --force || echo "⚠️  Failed to install $ext"
        sleep 0.3
      fi
    done < "$file"
  done
else
  echo "⚠️  VS Code CLI (code) not found"
fi

echo "✅ VS Code setup complete!"
