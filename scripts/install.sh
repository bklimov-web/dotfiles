#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🚀 Starting environment setup..."

# --------------------------------------------------------------------
# 🧰 1. Проверка и установка Homebrew
# --------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "✅ Homebrew already installed"
fi

brew update

# --------------------------------------------------------------------
# 🔤 2. Шрифт для Powerlevel10k
# --------------------------------------------------------------------
echo "🔤 Installing Meslo Nerd Font..."

FONT_DIR="$HOME/Library/Fonts"
MESLO_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"

mkdir -p "$FONT_DIR"
cd "$FONT_DIR"

if [ ! -f "$FONT_DIR/MesloLGS NF Regular.ttf" ]; then
  echo "⬇️  Downloading MesloLGS Nerd Font..."
  curl -fLo Meslo.zip "$MESLO_URL"
  unzip -o Meslo.zip >/dev/null
  rm Meslo.zip
  echo "✅ Meslo Nerd Font installed in $FONT_DIR"
else
  echo "✅ Meslo Nerd Font already installed"
fi

cd -

# --------------------------------------------------------------------
# ⚙️ 3. CLI утилиты
# --------------------------------------------------------------------
echo "⚙️ Installing CLI utilities..."
brew install fzf thefuck zoxide fd bat eza git-lfs fnm

# Настройка fzf (key bindings и completion)
if [ -f "$(brew --prefix)/opt/fzf/install" ]; then
  yes | "$(brew --prefix)/opt/fzf/install" --no-update-rc --key-bindings --completion
fi

# --------------------------------------------------------------------
# 🐚 4. Oh My Zsh + Powerlevel10k + плагины
# --------------------------------------------------------------------
echo "🐚 Installing Oh My Zsh..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ Oh My Zsh already installed"
fi

# --- Powerlevel10k ---
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "🎨 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "✅ Powerlevel10k already installed"
fi

# --- Plugins ---
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "💬 Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "🌈 Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# --------------------------------------------------------------------
# 🔗 5. Симлинки через stow
# --------------------------------------------------------------------
echo "🔗 Linking dotfiles via stow..."

BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for file in ~/.zshrc ~/.p10k.zsh; do
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    echo "⚠️  Found existing $file — moving to $BACKUP_DIR"
    mv "$file" "$BACKUP_DIR/"
  fi
done

cd "$DOTFILES"
stow --restow zsh

# --------------------------------------------------------------------
# 🧠 6. Сделать zsh оболочкой по умолчанию
# --------------------------------------------------------------------
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "🧠 Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

# --------------------------------------------------------------------
# 🗂️ 7. Yazi file manager
# --------------------------------------------------------------------
echo "🗂️ Installing Yazi and dependencies..."

brew install yazi ffmpeg@7 sevenzip jq poppler fd ripgrep fzf zoxide resvg imagemagick font-symbols-only-nerd-font
# ffmpeg@7 — keg-only, без линка `ffmpeg` не попадёт в PATH
brew link --overwrite --force ffmpeg@7

# Создание симлинков
cd "$DOTFILES"
stow --restow yazi

echo "✅ Yazi installed and configured!"

# --------------------------------------------------------------------
# 🧹 8. Финал
# --------------------------------------------------------------------
echo ""
echo "✅ Installation complete!"
echo "➡️  Restart your terminal or run: exec zsh"
echo "💡 If Powerlevel10k asks for configuration, go through setup once."
