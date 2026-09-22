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

echo "🔁 Restarting Finder and Dock..."
killall Finder
killall Dock

echo "✅ Done."
