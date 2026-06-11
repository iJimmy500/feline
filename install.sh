#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
DIM='\033[2m'
RESET='\033[0m'

VERSION=$(cat "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/VERSION" 2>/dev/null || echo "1.0.0")
PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"

SCRIPTS=(
    feline-download
    feline-convert
    feline-clean
    feline-context
    feline-snap
    feline-search
    feline-scrape
    feline-lock
    feline-settings
    feline-ports
    feline-schedule
    feline-update
    feline-update-check
    feline-meow
)

print_done() {
    echo ""
    echo -e "${PURPLE}${BOLD}feline${RESET}${BOLD} $VERSION is installed.${RESET}"
    echo -e "Run ${CYAN}feline --help${RESET} to get started."
    echo ""
}

echo ""
echo -e "${PURPLE}${BOLD}feline${RESET}${BOLD} installer${RESET}  ${DIM}v${VERSION}${RESET}"
echo ""
echo -e "${YELLOW}${BOLD}⚠  Experimental software${RESET}"
echo -e "${YELLOW}   feline is under active development. Features may change or break"
echo -e "   without notice. Use at your own risk.${RESET}"
echo ""

# ── Detect macOS ───────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error:${RESET} feline requires macOS." >&2
    exit 1
fi

# ── Detect run mode ────────────────────────────────────────────────────────────
# Release mode: pre-built binary ships alongside this script in the same dir.
# Source mode:  running from a git clone with src/ and Makefile present.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_MODE=false

if [[ -f "$SCRIPT_DIR/feline" && -x "$SCRIPT_DIR/feline" ]]; then
    RELEASE_MODE=true
    BINARY="$SCRIPT_DIR/feline"
elif [[ -f "$SCRIPT_DIR/src/feline.c" ]]; then
    RELEASE_MODE=false
else
    echo -e "${RED}Error:${RESET} Could not find feline source or pre-built binary." >&2
    echo -e "${DIM}Re-download the release package from https://github.com/iJimmy500/feline/releases${RESET}" >&2
    exit 1
fi

# ── Ensure BINDIR is writable (request sudo once if needed) ───────────────────
need_sudo=false
if [[ ! -w "$BINDIR" ]]; then
    need_sudo=true
    echo -e "${YELLOW}Note:${RESET} ${BINDIR} isn't writable — will use sudo once to install."
    echo ""
    sudo -v || { echo -e "${RED}Error:${RESET} sudo failed."; exit 1; }
fi

install_file() {
    local src="$1" dst="$2" mode="${3:-755}"
    if $need_sudo; then
        sudo install -m "$mode" "$src" "$dst"
    else
        install -m "$mode" "$src" "$dst"
    fi
}

mkdir_p() {
    if $need_sudo; then
        sudo mkdir -p "$1"
    else
        mkdir -p "$1"
    fi
}

mkdir_p "$BINDIR"

# ── Build or use pre-built binary ─────────────────────────────────────────────
if $RELEASE_MODE; then
    echo -e "${CYAN}Installing pre-built feline binary...${RESET}"
    install_file "$BINARY" "$BINDIR/feline"
else
    echo -e "${CYAN}Building feline...${RESET}"

    if ! command -v cc &>/dev/null; then
        echo -e "${RED}Error:${RESET} C compiler not found." >&2
        echo -e "${DIM}Install Xcode Command Line Tools with: xcode-select --install${RESET}" >&2
        exit 1
    fi

    cd "$SCRIPT_DIR"
    make --no-print-directory PREFIX="$PREFIX" 2>&1 | sed 's/^/  /'
    install_file "$SCRIPT_DIR/feline" "$BINDIR/feline"
    rm -f "$SCRIPT_DIR/feline"  # clean build artifact
fi

# ── Install scripts ────────────────────────────────────────────────────────────
echo -e "${CYAN}Installing scripts...${RESET}"

for name in "${SCRIPTS[@]}"; do
    # Scripts live alongside this install.sh in release mode,
    # or somewhere under src/ in source mode.
    if $RELEASE_MODE; then
        src_path="$SCRIPT_DIR/$name"
    else
        src_path=$(find "$SCRIPT_DIR/src" -name "$name" -type f 2>/dev/null | head -1)
    fi

    if [[ ! -f "$src_path" ]]; then
        echo -e "  ${YELLOW}skip${RESET}  $name ${DIM}(not found)${RESET}"
        continue
    fi

    install_file "$src_path" "$BINDIR/$name"
    echo -e "  ${GREEN}✓${RESET}  $name"
done

echo ""

# ── Dependency check ───────────────────────────────────────────────────────────
# Plain list + lookup function (not `declare -A`) so this still works under
# the bash 3.2 that ships with macOS.
OPTIONAL_DEPS=(ffmpeg yt-dlp magick pandoc)

brew_formula() {
    case "$1" in
        magick) echo "imagemagick" ;;
        *)      echo "$1" ;;
    esac
}

MISSING=()

echo -e "${BOLD}Checking optional dependencies...${RESET}"
echo -e "${DIM}(these add extra capabilities — feline works without them)${RESET}"
echo ""

for bin in "${OPTIONAL_DEPS[@]}"; do
    if command -v "$bin" &>/dev/null; then
        echo -e "  ${GREEN}✓${RESET}  $bin"
    else
        echo -e "  ${DIM}–${RESET}  $bin  ${DIM}($(brew_formula "$bin"))${RESET}"
        MISSING+=("$bin")
    fi
done
echo ""

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo -e "${GREEN}All optional tools are installed.${RESET}"
    print_done
    exit 0
fi

# ── Offer to install missing deps via Homebrew ─────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo -e "${DIM}Install Homebrew (https://brew.sh) to get the optional tools later.${RESET}"
    print_done
    exit 0
fi

FORMULAS=()
for bin in "${MISSING[@]}"; do
    FORMULAS+=("$(brew_formula "$bin")")
done

# When run via `curl | bash`, stdin is not a terminal — skip the prompt
# instead of dying on EOF (set -e would abort the whole install).
if [[ ! -t 0 ]]; then
    echo -e "${DIM}Non-interactive install — skipping optional tools.${RESET}"
    echo -e "${DIM}Install later with: brew install ${FORMULAS[*]}${RESET}"
    print_done
    exit 0
fi

echo -e "Install missing tools now? ${DIM}(${FORMULAS[*]})${RESET}"
echo -n -e "${BOLD}[y/n]:${RESET} "
read -r ANSWER

if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
    echo ""
    brew install "${FORMULAS[@]}"
    echo ""
    echo -e "${GREEN}All dependencies installed.${RESET}"
else
    echo ""
    echo -e "${DIM}Skipped. Install later with: brew install ${FORMULAS[*]}${RESET}"
fi

print_done
