#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Профиль машины: ./install.sh personal|work (или MACHINE_PROFILE в окружении)
PROFILE="${1:-${MACHINE_PROFILE:-}}"

# git-хуки репозитория (проверка секретов перед коммитом)
git -C "$DOTFILES" config core.hooksPath .githooks

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

# сразу после установки brew ещё не в PATH (Apple Silicon: /opt/homebrew, Intel: /usr/local)
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
done
unset _brew

brew update

# --------------------------------------------------------------------
# 📦 2. Brewfile: общий слой + слой профиля (CLI, шрифты, зависимости yazi и т.д.)
# --------------------------------------------------------------------
echo "📦 Installing Brewfile layers (profile: ${PROFILE:-none})..."
# сбой одного пакета (например, приложение уже стоит вручную) не должен ронять весь скрипт
brew bundle --file="$DOTFILES/brew/Brewfile" || echo "⚠️  brew bundle (общий слой) завершился с ошибками — проверь вывод выше"
if [ -n "$PROFILE" ] && [ -f "$DOTFILES/brew/Brewfile.$PROFILE" ]; then
  brew bundle --file="$DOTFILES/brew/Brewfile.$PROFILE" || echo "⚠️  brew bundle ($PROFILE) завершился с ошибками — проверь вывод выше"
fi

# --------------------------------------------------------------------
# 🤖 3. Claude Code
# --------------------------------------------------------------------
# Нативный установщик, не brew: у Claude Code свой self-update
# (симлинк в ~/.local/share/claude/versions/...), ставить через brew
# означало бы два независимых бинарника и два конкурирующих апдейтера.
if ! command -v claude &>/dev/null; then
  echo "🤖 Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "✅ Claude Code already installed"
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

# Остальные пакеты (сами программы уже поставлены Brewfile)
stow --restow yazi nvim karabiner ccstatusline git

# name/email для git лежат вне репозитория
if [ ! -f ~/.gitconfig.local ]; then
  echo "⚠️  Создай ~/.gitconfig.local с [user] name и email (см. README)"
fi

# --------------------------------------------------------------------
# 🧠 6. Сделать zsh оболочкой по умолчанию
# --------------------------------------------------------------------
if [[ "$SHELL" != "$(which zsh)" ]]; then
  echo "🧠 Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

# Запомнить профиль для zsh (файл вне репозитория)
if [ -n "$PROFILE" ] && ! grep -q '^export MACHINE_PROFILE=' ~/.zshrc.local 2>/dev/null; then
  echo "export MACHINE_PROFILE=$PROFILE" >> ~/.zshrc.local
fi

# --------------------------------------------------------------------
# 🧹 7. Финал
# --------------------------------------------------------------------
echo ""
echo "✅ Installation complete!"
echo "➡️  Restart your terminal or run: exec zsh"
echo "💡 If Powerlevel10k asks for configuration, go through setup once."
