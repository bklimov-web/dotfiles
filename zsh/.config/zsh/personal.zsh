# Только для личных машин (MACHINE_PROFILE=personal в ~/.zshrc.local)

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# скрипты и функции: каждый файл в personal.d/ подключается автоматически
for _f in ~/.config/zsh/personal.d/*.zsh(N); do source "$_f"; done
unset _f
