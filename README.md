# dotfiles

Конфиги, которые линкуются в `$HOME` через [GNU Stow](https://www.gnu.org/software/stow/).
Каждая папка верхнего уровня — отдельный stow-пакет, внутри неё путь повторяет путь от `$HOME`.

| Пакет   | Что внутри                              | Куда линкуется                                   |
|---------|-----------------------------------------|--------------------------------------------------|
| `zsh`   | `.zshrc`, `.p10k.zsh`, `.config/zsh/`   | `~/.zshrc`, `~/.p10k.zsh`, `~/.config/zsh/`      |
| `yazi`  | `.config/yazi/*.toml`                   | `~/.config/yazi/`                                |
| `vscode`| `Library/Application Support/Code/User` | `~/Library/Application Support/Code/User/`       |

`vscode/extensions*.txt` — списки расширений, они не линкуются (см. `.stowrc`).

## Установка с нуля

```bash
git clone <repo> ~/dotfiles
~/dotfiles/scripts/install.sh personal      # или work; без аргумента — только общий слой
~/dotfiles/scripts/install-vscode.sh personal
```

`install.sh`: brew, oh-my-zsh, p10k, плагины, yazi, stow (zsh + yazi), затем
`brew bundle` для `brew/Brewfile` и `brew/Brewfile.<профиль>`. Профиль запоминается в
`~/.zshrc.local` как `MACHINE_PROFILE`. `install-vscode.sh`: stow vscode и расширения
из `extensions.txt` + `extensions.<профиль>.txt`.

## Только симлинки

`.stowrc` уже задаёт `--target=$HOME`, поэтому из папки репо:

```bash
stow zsh yazi vscode        # создать
stow -R zsh                 # пересоздать один пакет
stow -D yazi                # снять симлинки
stow -n -v zsh              # пробный прогон, ничего не меняет
```

## Слои: общий и по профилям

| Что        | Все машины              | Только `personal`             | Только `work`             |
|------------|-------------------------|-------------------------------|---------------------------|
| Homebrew   | `brew/Brewfile`         | `brew/Brewfile.personal`      | `brew/Brewfile.work`      |
| Расширения | `vscode/extensions.txt` | `vscode/extensions.personal.txt` | `vscode/extensions.work.txt` |
| zsh        | `.zshrc`                | `.config/zsh/personal.zsh`    | (добавить по аналогии)    |

```bash
brew bundle --file=brew/Brewfile
brew bundle --file=brew/Brewfile.personal   # на личной машине
```

Не используй `brew bundle dump` как рабочий инструмент: он выгружает всё
установленное в один файл и смешивает слои.

## Как обновлять

Поставил что-то новое на любой машине — реши, в какой слой это идёт, и допиши строку:

```bash
brew install foo                      # затем строка в нужный файл:
echo 'brew "foo"' >> brew/Brewfile.work       # только работа
echo 'cask "bar"' >> brew/Brewfile            # все машины

code --install-extension publisher.name
echo 'publisher.name' >> vscode/extensions.work.txt   # или extensions.txt
```

Формат строк Brewfile: `brew "имя"`, `cask "имя"`, `go "путь"`.
Потом `git commit && git push`; на других машинах `git pull` и снова `brew bundle`
(`install-vscode.sh <профиль>` для расширений).

### Что установлено, но не записано

```bash
./scripts/sync-check.sh            # профиль берётся из MACHINE_PROFILE
./scripts/sync-check.sh work       # или явно
```

Сверяет установленное с общим слоем и слоем **текущего** профиля и показывает brew-пакеты
и расширения VS Code, которых там нет. Если пакет записан только в слое другого профиля,
рядом будет пометка `← есть в слое: work (перенести в общий?)`: он нужен и на этой машине,
значит, его стоит перенести в общий слой. Только читает, ничего не удаляет.

## Локальное и рабочее

Всё, что не должно попадать в репозиторий (рабочие алиасы, ключи, AWS-профили),
лежит в `~/.zshrc.local` — он подключается в конце `.zshrc`.

### Профили машин

В `~/.zshrc.local` задаётся `export MACHINE_PROFILE=personal`. Если он равен
`personal`, `.zshrc` подключает `zsh/.config/zsh/personal.zsh` (сейчас там bun).
Новый слой (например, `work`) добавляется так же: файл рядом + строка в `.zshrc`.

## Секреты и личные значения

Правило: **в репозитории только код, значения приходят снаружи**.

| Что | Где |
|---|---|
| Не секрет (регион, имя профиля) | значение по умолчанию в коде, переопределяется переменной |
| Приватное (instance-id, хосты) | `~/.zshrc.local`, вне репозитория |
| Секреты (токены, ключи) | Keychain (`security find-generic-password`) или 1Password (`op read`), читать **в момент вызова**, не при старте шелла |

Скрипты и функции для профиля `personal` лежат в `zsh/.config/zsh/personal.d/*.zsh`
и подключаются автоматически; новый файл подхватывается без правок `.zshrc`.
Переменные для них (например `VALHEIM_INSTANCE_ID`) задаются в `~/.zshrc.local`.

### Защита от случайной утечки

`gitleaks` проверяет staged-изменения перед коммитом (`.githooks/pre-commit`).
После клонирования включи хуки один раз:

```bash
brew install gitleaks
git config core.hooksPath .githooks
gitleaks git --redact    # проверить всю историю
```
