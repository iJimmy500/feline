#!/usr/bin/env bash
# Builds a distributable release tarball for feline.
#
# Output: dist/feline-VERSION-macos.tar.gz
#         dist/feline-VERSION-macos.tar.gz.sha256
#
# The tarball is self-contained: extract and run ./install.sh.
# No compiler or Xcode required on the target machine.

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION=$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.0.0")
NAME="feline-${VERSION}-macos"
DIST="$SCRIPT_DIR/dist"
STAGING="$DIST/$NAME"

SCRIPTS=(
    download/feline-download
    convert/feline-convert
    clean/feline-clean
    context/feline-context
    snap/feline-snap
    search/feline-search
    scrape/feline-scrape
    lock/feline-lock
    settings/feline-settings
    ports/feline-ports
    schedule/feline-schedule
    update/feline-update
    update/feline-update-check
    meow/feline-meow
)

# ── Sanity checks ──────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error:${RESET} release.sh must be run on macOS." >&2
    exit 1
fi

if ! command -v cc &>/dev/null; then
    echo -e "${RED}Error:${RESET} C compiler not found. Install Xcode Command Line Tools:" >&2
    echo -e "  xcode-select --install" >&2
    exit 1
fi

echo ""
echo -e "${BOLD}feline release builder${RESET}  ${DIM}v${VERSION}${RESET}"
echo ""

# ── Clean staging area ─────────────────────────────────────────────────────────
rm -rf "$STAGING"
mkdir -p "$STAGING"

# ── Build universal binary ─────────────────────────────────────────────────────
echo -e "${CYAN}Building...${RESET}"

CFLAGS="-Os -Wall -Wextra -std=c11"
LDFLAGS="-Wl,-x,-S,-dead_strip"

cc $CFLAGS $LDFLAGS -target arm64-apple-macos11   -o "$DIST/feline-arm64"   src/feline.c
cc $CFLAGS $LDFLAGS -target x86_64-apple-macos10.15 -o "$DIST/feline-x86_64" src/feline.c

lipo -create -output "$STAGING/feline" "$DIST/feline-arm64" "$DIST/feline-x86_64"
strip "$STAGING/feline" 2>/dev/null || true
chmod 755 "$STAGING/feline"

rm -f "$DIST/feline-arm64" "$DIST/feline-x86_64"

ARCH=$(lipo -archs "$STAGING/feline")
SIZE=$(du -sh "$STAGING/feline" | cut -f1)
echo -e "  ${GREEN}✓${RESET}  feline  ${DIM}(${SIZE}, ${ARCH})${RESET}"

# ── Copy scripts ───────────────────────────────────────────────────────────────
for s in "${SCRIPTS[@]}"; do
    name="$(basename "$s")"
    cp "src/$s" "$STAGING/$name"
    chmod 755 "$STAGING/$name"
    echo -e "  ${GREEN}✓${RESET}  $name"
done

# ── Copy support files ─────────────────────────────────────────────────────────
cp install.sh   "$STAGING/install.sh"
cp uninstall.sh "$STAGING/uninstall.sh"
cp README.md    "$STAGING/README.md"
chmod 755 "$STAGING/install.sh" "$STAGING/uninstall.sh"

# ── Create tarball ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}Packaging...${RESET}"

TARBALL="$DIST/${NAME}.tar.gz"
tar -C "$DIST" -czf "$TARBALL" "$NAME"
rm -rf "$STAGING"

# Checksum
shasum -a 256 "$TARBALL" | awk '{print $1}' > "${TARBALL}.sha256"
CHECKSUM=$(cat "${TARBALL}.sha256")
TARBALL_SIZE=$(du -sh "$TARBALL" | cut -f1)

echo ""
echo -e "${GREEN}${BOLD}Release ready:${RESET}"
echo -e "  ${BOLD}$TARBALL${RESET}"
echo -e "  ${DIM}Size:     ${TARBALL_SIZE}${RESET}"
echo -e "  ${DIM}SHA-256:  ${CHECKSUM}${RESET}"
echo ""
echo -e "${DIM}Next steps:${RESET}"
echo -e "  1. Create a GitHub release tagged v${VERSION}"
echo -e "  2. Upload ${NAME}.tar.gz and ${NAME}.tar.gz.sha256"
echo -e "  3. Update Formula/feline.rb with the URL and sha256"
echo -e "  4. Users install with:"
echo -e "     ${CYAN}curl -fsSL https://raw.githubusercontent.com/iJimmy500/feline/main/get.sh | bash${RESET}"
echo ""
