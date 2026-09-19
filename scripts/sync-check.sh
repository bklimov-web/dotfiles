#!/bin/bash
# Показывает, что установлено на машине, но не записано в её слоях dotfiles
# (общий слой + слой текущего профиля). Только читает, ничего не меняет.
#
#   ./scripts/sync-check.sh [профиль]     # по умолчанию MACHINE_PROFILE
#
# Если пакет установлен и записан только в СЛОЕ ДРУГОГО профиля, скрипт это
# покажет: значит, он нужен и здесь, и, возможно, его пора перенести в общий слой.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${1:-${MACHINE_PROFILE:-}}"

echo "Профиль: ${PROFILE:-нет (только общий слой)}"

# Слои, в которых лежит эта строка, кроме общего и текущего профиля.
# $1 — шаблон для grep -F, остальное — файлы.
other_layers() {
  local needle="$1"; shift
  local found=() f
  for f in "$@"; do
    grep -qiF -- "$needle" "$f" 2>/dev/null && found+=("$(basename "$f" | sed -E 's/^(Brewfile|extensions)\.?//; s/\.txt$//')")
  done
  echo "${found[*]}"
}

# --------------------------------------------------------------------
# Brew
# --------------------------------------------------------------------
echo ""
echo "🍺 Brew: установлено, но нет в общем слое${PROFILE:+ и в слое $PROFILE}"
if command -v brew &>/dev/null; then
  MINE="$(mktemp)"
  cat "$DOTFILES/brew/Brewfile" > "$MINE"
  [ -n "$PROFILE" ] && [ -f "$DOTFILES/brew/Brewfile.$PROFILE" ] && cat "$DOTFILES/brew/Brewfile.$PROFILE" >> "$MINE"

  # без --force cleanup только выводит список, ничего не удаляет
  out="$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle cleanup --file="$MINE" 2>/dev/null \
    | grep -v -e '^Would ' -e '^Run `brew bundle cleanup' -e '^$')"
  rm -f "$MINE"

  if [ -z "$out" ]; then
    echo "  — всё записано"
  else
    others=()
    for f in "$DOTFILES"/brew/Brewfile.*; do
      [ "$(basename "$f")" = "Brewfile.$PROFILE" ] || others+=("$f")
    done
    while IFS= read -r name; do
      layers="$(other_layers "\"$name\"" "${others[@]}")"
      if [ -n "$layers" ]; then
        echo "  $name   ← есть в слое: $layers (перенести в общий?)"
      else
        echo "  $name"
      fi
    done <<< "$out"
  fi
else
  echo "  brew не найден"
fi

# --------------------------------------------------------------------
# VS Code
# --------------------------------------------------------------------
echo ""
echo "🧩 VS Code: установлено, но нет в общем слое${PROFILE:+ и в слое $PROFILE}"
if command -v code &>/dev/null; then
  mine=("$DOTFILES/vscode/extensions.txt")
  [ -n "$PROFILE" ] && [ -f "$DOTFILES/vscode/extensions.$PROFILE.txt" ] && mine+=("$DOTFILES/vscode/extensions.$PROFILE.txt")

  out="$(comm -23 \
    <(code --list-extensions | tr 'A-Z' 'a-z' | sort) \
    <(cat "${mine[@]}" | grep -v -e '^#' -e '^$' | tr 'A-Z' 'a-z' | sort -u))"

  if [ -z "$out" ]; then
    echo "  — всё записано"
  else
    others=()
    for f in "$DOTFILES"/vscode/extensions.*.txt; do
      [ "$(basename "$f")" = "extensions.$PROFILE.txt" ] || others+=("$f")
    done
    while IFS= read -r ext; do
      layers="$(other_layers "$ext" "${others[@]}")"
      if [ -n "$layers" ]; then
        echo "  $ext   ← есть в слое: $layers (перенести в общий?)"
      else
        echo "  $ext"
      fi
    done <<< "$out"
  fi
else
  echo "  code не найден"
fi

echo ""
echo "➡️  Добавь нужное в brew/Brewfile[.профиль] или vscode/extensions[.профиль].txt"
