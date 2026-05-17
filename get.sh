#!/usr/bin/env bash
# feline installer — fetches the latest release and runs install.sh
#
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/iJimmy500/feline/main/get.sh | bash

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

REPO="iJimmy500/feline"
VERSION="1.0.0"
BASE_URL="https://github.com/${REPO}/releases/download/v${VERSION}"
TARBALL="feline-${VERSION}-macos.tar.gz"
CHECKSUM_FILE="${TARBALL}.sha256"

echo ""
echo -e "${BOLD}feline installer${RESET}  ${DIM}v${VERSION}${RESET}"
echo ""

# ── macOS only ─────────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error:${RESET} feline requires macOS." >&2
    exit 1
fi

# ── Require curl ───────────────────────────────────────────────────────────────
if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error:${RESET} curl is required but not found." >&2
    exit 1
fi

# ── Download to temp dir ───────────────────────────────────────────────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo -e "${CYAN}Downloading feline ${VERSION}...${RESET}"
curl -fsSL --progress-bar \
    "${BASE_URL}/${TARBALL}" \
    -o "${TMP}/${TARBALL}"

curl -fsSL \
    "${BASE_URL}/${CHECKSUM_FILE}" \
    -o "${TMP}/${CHECKSUM_FILE}"

# ── Verify checksum ────────────────────────────────────────────────────────────
echo -e "${CYAN}Verifying...${RESET}"
EXPECTED=$(cat "${TMP}/${CHECKSUM_FILE}")
ACTUAL=$(shasum -a 256 "${TMP}/${TARBALL}" | awk '{print $1}')

if [[ "$EXPECTED" != "$ACTUAL" ]]; then
    echo -e "${RED}Error:${RESET} Checksum mismatch — download may be corrupt." >&2
    echo -e "  expected: $EXPECTED" >&2
    echo -e "  got:      $ACTUAL" >&2
    exit 1
fi

echo -e "  ${GREEN}✓${RESET}  checksum OK"
echo ""

# ── Extract and install ────────────────────────────────────────────────────────
tar -xzf "${TMP}/${TARBALL}" -C "$TMP"
EXTRACTED="${TMP}/feline-${VERSION}-macos"

bash "${EXTRACTED}/install.sh"
