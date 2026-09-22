#!/bin/bash
# macOS defaults: Finder и Dock.
# Безопасно перезапускать: каждая команда просто перезаписывает значение.
set -e

echo "🖥️  Applying macOS defaults..."

# --------------------------------------------------------------------
# Клавиатура
# --------------------------------------------------------------------
# Быстрый повтор клавиши, короткая задержка перед началом повтора
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Зажатие клавиши повторяет символ вместо попапа с акцентами
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Без автозамен, которые мешают в терминале/коде
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# --------------------------------------------------------------------
# Трекпад
# --------------------------------------------------------------------
# Tap to click — три ключа: два по драйверу (проводной/Bluetooth трекпад)
# и один общий, который читает System Settings и экран логина
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# --------------------------------------------------------------------
# Finder
# --------------------------------------------------------------------
# Показывать скрытые файлы (.env, .git и т.д.)
defaults write com.apple.finder AppleShowAllFiles -bool true
# Показывать расширения файлов всегда
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Путь до текущей папки внизу окна
defaults write com.apple.finder ShowPathbar -bool true
# Строка статуса (число файлов, свободное место)
defaults write com.apple.finder ShowStatusBar -bool true

# --------------------------------------------------------------------
# Dock
# --------------------------------------------------------------------
# Автоскрытие без задержки перед появлением/скрытием
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
# Размер иконок (стандарт ~48)
defaults write com.apple.dock tilesize -int 33
# Не показывать недавние приложения — только закреплённые
defaults write com.apple.dock show-recents -bool false

# --------------------------------------------------------------------
# Spotlight / Raycast
# --------------------------------------------------------------------
# Выключить стандартный Cmd+Space у Spotlight (ключ 64 = "Show Spotlight
# search" в com.apple.symbolichotkeys), чтобы combo было свободно для Raycast.
# 65 ("Show Finder search window", Cmd+Option+Space) оставляем как есть.
#
# defaults write/-dict-add тут не годится: он бы заменил весь узел "64"
# целиком, включая вложенный value с параметрами комбинации. PlistBuddy
# позволяет пересобрать узел точечно и одинаково и для новой машины
# (ключа 64 ещё нет), и для уже тронутой (ключ есть) — Delete молча
# игнорирует отсутствие ключа, Add затем создаёт его заново.
HOTKEYS_PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
/usr/libexec/PlistBuddy -c "Delete :AppleSymbolicHotKeys:64" "$HOTKEYS_PLIST" 2>/dev/null
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64 dict" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:enabled bool false" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value dict" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:type string standard" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters array" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters:0 integer 65535" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters:1 integer 49" "$HOTKEYS_PLIST"
/usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:value:parameters:2 integer 1048576" "$HOTKEYS_PLIST"

# Raycast: сам открывается по Cmd+Space (49 — код клавиши Space)
if [ -d /Applications/Raycast.app ]; then
  defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49"
fi

echo "🔁 Restarting Finder, Dock, SystemUIServer и сбрасываю кеш preferences..."
killall Finder
killall Dock
killall SystemUIServer 2>/dev/null || true
# PlistBuddy пишет в файл напрямую, мимо кеша cfprefsd — без этого
# правка Spotlight может не примениться до следующего логина
killall cfprefsd 2>/dev/null || true

echo "✅ Done."
echo "ℹ️  Если Raycast уже был открыт, перезапусти его, чтобы hotkey подхватился."
