echo "🧩 Setting up VS Code configuration..."

# 1. Симлинки настроек
stow --restow vscode

# 2. Установка расширений
if command -v code &>/dev/null; then
  echo "📦 Installing VS Code extensions..."
  xargs -n1 code --install-extension <~/dotfiles/vscode/extensions.txt
else
  echo "⚠️ VS Code CLI not found (install or add to PATH)"
fi
