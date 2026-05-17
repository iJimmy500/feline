#!/usr/bin/env bash
# Bump the feline version, commit, and tag.
#
# Usage: ./bump.sh <new-version>
# Example: ./bump.sh 1.1.0

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ $# -ne 1 ]]; then
    echo -e "${RED}Usage:${RESET} ./bump.sh <new-version>" >&2
    echo -e "${DIM}Example: ./bump.sh 1.1.0${RESET}" >&2
    exit 1
fi

NEW="$1"
OLD=$(cat VERSION)

if [[ "$NEW" == "$OLD" ]]; then
    echo -e "${RED}Error:${RESET} $NEW is already the current version." >&2
    exit 1
fi

echo ""
echo -e "${BOLD}Bumping feline${RESET}  ${DIM}${OLD} → ${NEW}${RESET}"
echo ""

files=(
    "VERSION"
    "get.sh"
    "src/feline.c"
)

for f in "${files[@]}"; do
    sed -i '' "s/${OLD}/${NEW}/g" "$f"
    echo -e "  ${GREEN}✓${RESET}  $f"
done

echo ""

git add VERSION get.sh src/feline.c install.sh release.sh
git commit -m "chore: bump version to ${NEW}"
git tag "v${NEW}"

echo ""
echo -e "${GREEN}${BOLD}Done.${RESET}  Tagged v${NEW}."
echo ""
echo -e "${DIM}Push with:${RESET}"
echo -e "  git push && git push origin v${NEW}"
echo ""
