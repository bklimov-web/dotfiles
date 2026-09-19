# dotfiles

Конфиги, которые линкуются в `$HOME` через [GNU Stow](https://www.gnu.org/software/stow/).
Каждая папка верхнего уровня — отдельный stow-пакет, внутри неё путь повторяет путь от `$HOME`.

| Пакет   | Что внутри                              | Куда линкуется                                   |
|---------|-----------------------------------------|--------------------------------------------------|
| `zsh`   | `.zshrc`, `.p10k.zsh`, `.config/zsh/`   | `~/.zshrc`, `~/.p10k.zsh`, `~/.config/zsh/`      |
| `yazi`  | `.config/yazi/*.toml`                   | `~/.config/yazi/`                                |
| `vscode`| `Library/Application Support/Code/User` | `~/Library/Application Support/Code/User/`       |

`vscode/extensions.txt` — список расширений, он не линкуется (см. `.stowrc`).

## Установка с нуля

```bash
git clone <repo> ~/dotfiles
~/dotfiles/scripts/install.sh          # brew, oh-my-zsh, p10k, плагины, yazi, stow zsh+yazi
~/dotfiles/scripts/install-vscode.sh   # stow vscode + расширения
```

## Только симлинки

`.stowrc` уже задаёт `--target=$HOME`, поэтому из папки репо:

```bash
stow zsh yazi vscode        # создать
stow -R zsh                 # пересоздать один пакет
stow -D yazi                # снять симлинки
stow -n -v zsh              # пробный прогон, ничего не меняет
```

## Homebrew

Список разбит на слои в `brew/`:

| Файл                  | Для чего                       |
|-----------------------|--------------------------------|
| `brew/Brewfile`       | база, нужна на всех машинах    |
| `brew/Brewfile.personal` | только личные машины        |

```bash
brew bundle --file=brew/Brewfile
brew bundle --file=brew/Brewfile.personal   # на личной машине
brew bundle cleanup --file=brew/Brewfile    # показать установленное, чего нет в файле
```

Не используй `brew bundle dump` как рабочий инструмент: он выгружает всё
установленное в один файл и смешивает слои.

## Локальное и рабочее

Всё, что не должно попадать в репозиторий (рабочие алиасы, ключи, AWS-профили),
лежит в `~/.zshrc.local` — он подключается в конце `.zshrc`.

### Профили машин

В `~/.zshrc.local` задаётся `export MACHINE_PROFILE=personal`. Если он равен
`personal`, `.zshrc` подключает `zsh/.config/zsh/personal.zsh` (сейчас там bun).
Новый слой (например, `work`) добавляется так же: файл рядом + строка в `.zshrc`.
