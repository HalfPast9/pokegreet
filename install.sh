#!/bin/sh
# pokegreet installer
#   curl -fsSL https://raw.githubusercontent.com/HalfPast9/pokegreet/main/install.sh | sh
#
# env:
#   POKEGREET_BIN_DIR=...   where to put the script (default ~/.local/bin)
#   POKEGREET_NO_RC=1       don't touch your shell startup file
set -eu

REPO_RAW="https://raw.githubusercontent.com/HalfPast9/pokegreet/main"
BIN_DIR="${POKEGREET_BIN_DIR:-$HOME/.local/bin}"
MARK="# pokegreet: wild Pokémon on terminal startup"

say()  { printf '%s\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }

# 1. requirements
if ! command -v python3 >/dev/null 2>&1; then
    warn "pokegreet needs python3 (3.9+)."; exit 1
fi
if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
    warn "pokegreet needs Python 3.9+ (3.11+ to use a config file)."; exit 1
fi
if ! command -v pokemon-colorscripts >/dev/null 2>&1; then
    warn "pokemon-colorscripts isn't installed. pokegreet uses its sprites, so install it too:"
    warn "  git clone https://gitlab.com/phoneybadger/pokemon-colorscripts.git"
    warn "  cd pokemon-colorscripts && sudo ./install.sh"
    warn "  (Arch: yay -S pokemon-colorscripts-git)"
    warn "Continuing with the pokegreet install."
fi

# 2. the script itself: from this checkout if we're in one, otherwise from GitHub
mkdir -p "$BIN_DIR"
here=$(dirname "$0")
if [ -f "$here/pokegreet" ] && [ -f "$here/install.sh" ]; then
    if [ "$here/pokegreet" -ef "$BIN_DIR/pokegreet" ]; then
        say "$BIN_DIR/pokegreet already points at this checkout"
    else
        cp "$here/pokegreet" "$BIN_DIR/pokegreet"
    fi
else
    curl -fsSL "$REPO_RAW/pokegreet" -o "$BIN_DIR/pokegreet"
fi
chmod +x "$BIN_DIR/pokegreet"
say "installed $BIN_DIR/pokegreet"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR isn't on your PATH. Add this to your shell startup file:"
       warn "  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

# 3. run it whenever an interactive shell starts
if [ "${POKEGREET_NO_RC:-}" = 1 ]; then
    say "skipping shell setup (POKEGREET_NO_RC=1). Add 'pokegreet' to your shell startup yourself."
    exit 0
fi

shell=$(basename "${SHELL:-sh}")
case "$shell" in
    bash) rc="$HOME/.bashrc" ;;
    zsh)  rc="${ZDOTDIR:-$HOME}/.zshrc" ;;
    fish) rc="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish" ;;
    *)    say "don't know how to set up '$shell'. Run 'pokegreet' from its startup file."; exit 0 ;;
esac

if [ -f "$rc" ] && grep -q 'pokegreet' "$rc"; then
    say "$rc already runs pokegreet"
else
    mkdir -p "$(dirname "$rc")"
    if [ "$shell" = fish ]; then
        hook='status is-interactive; and type -q pokegreet; and pokegreet'
    else
        hook='case $- in *i*) command -v pokegreet >/dev/null && pokegreet ;; esac'
    fi
    printf '\n%s\n%s\n' "$MARK" "$hook" >> "$rc"
    say "added pokegreet to $rc"
fi

if [ -f "$rc" ] && grep -q 'pokemon-colorscripts' "$rc"; then
    warn "$rc also runs pokemon-colorscripts. Remove that line unless you want two Pokémon."
fi

say ""
say "Done! Open a new terminal to meet your first wild Pokémon."
say "  pokegreet --dex   see your progress"
say "  pokegreet --help  everything else"
