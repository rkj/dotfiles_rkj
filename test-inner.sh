#!/usr/bin/env bash
# Inner test script, run inside Docker as testuser.
set -eu

PASS=0; FAIL=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

cd ~/dotfiles_rkj
echo "=== Running init.sh ==="
./init.sh

echo ""
echo "=== Symlinks (links/) ==="
check "~/.vimrc is symlink"        test -L ~/.vimrc
check "~/.gitattributes is symlink" test -L ~/.gitattributes
check "~/.gitignore is symlink"    test -L ~/.gitignore

echo ""
echo "=== Config symlinks (~/.config/) ==="
check "~/.config/fish is symlink"  test -L ~/.config/fish
check "~/.config/kitty is symlink" test -L ~/.config/kitty
check "~/.config/yazi is symlink"  test -L ~/.config/yazi

echo ""
echo "=== Stubs ==="
check "~/.tmux.conf exists"       test -f ~/.tmux.conf
check "~/.gitconfig exists"       test -f ~/.gitconfig
check "~/.zshrc exists"           test -f ~/.zshrc

echo ""
echo "=== DOTFILES in .profile ==="
check "DOTFILES export in .profile" grep -q "^export DOTFILES=" ~/.profile
echo "  .profile DOTFILES line: $(grep 'export DOTFILES=' ~/.profile)"

echo ""
echo "=== Shell integration ==="

DOTFILES_VAL=$(bash -l -c 'echo "$DOTFILES"' 2>/dev/null || echo "")
check "DOTFILES set in bash login" test -n "$DOTFILES_VAL"
echo "  bash DOTFILES=$DOTFILES_VAL"

ZSH_VAL=$(zsh -lic 'echo "$DOTFILES"' 2>&1 | grep -v "notification" || echo "")
check "DOTFILES set in zsh login" test -n "$ZSH_VAL"
echo "  zsh DOTFILES=$ZSH_VAL"

FISH_VAL=$(fish -c 'echo $DOTFILES' 2>/dev/null || echo "")
check "DOTFILES set in direct fish" test -n "$FISH_VAL"
echo "  fish direct DOTFILES=$FISH_VAL"

FISH_PATH=$(fish -c 'echo $PATH' 2>/dev/null || echo "")
check "dotfiles/bin in fish PATH" bash -c "echo '$FISH_PATH' | grep -q 'dotfiles_rkj/bin'"

FISH_EDITOR=$(fish -c 'echo $EDITOR' 2>/dev/null || echo "")
check "EDITOR set in fish" test -n "$FISH_EDITOR"
echo "  fish EDITOR=$FISH_EDITOR"

echo ""
echo "=== Idempotency: run init.sh again ==="
./init.sh
check "second init.sh succeeds" true

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
test $FAIL -eq 0
