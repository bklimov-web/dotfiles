# Dotfiles symlinked on my machine

### Install with stow:

```bash
stow --target ~/.config .
```

### Homebrew installation:

```bash
# Leaving a maching
brew leaves > leaves.txt

# Fresh installation
xargs brew install < leaves.txt
```
