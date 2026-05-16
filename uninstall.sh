#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"
LIBDIR="$PREFIX/lib/feline"

# All binaries feline installs
BINS=(
    feline
    feline-download
    feline-convert
    feline-clean
    feline-context
    feline-snap
    feline-search
    feline-scrape
    feline-lock
)

echo ""
echo -e "${BOLD}feline uninstaller${RESET}"
echo ""

# ── Check if feline is actually installed ──────────────────────────────────────
FOUND=()
for bin in "${BINS[@]}"; do
    [[ -f "$BINDIR/$bin" ]] && FOUND+=("$BINDIR/$bin")
done
[[ -d "$LIBDIR" ]] && FOUND+=("$LIBDIR")

if [[ ${#FOUND[@]} -eq 0 ]]; then
    echo -e "${DIM}feline doesn't appear to be installed at $BINDIR.${RESET}"
    echo -e "${DIM}Nothing to remove.${RESET}"
    echo ""
    exit 0
fi

# ── Show what will be removed ──────────────────────────────────────────────────
echo -e "The following will be removed:"
echo ""
for item in "${FOUND[@]}"; do
    echo -e "  ${DIM}✕${RESET}  $item"
done
echo ""

# ── Confirm ────────────────────────────────────────────────────────────────────
echo -n -e "Remove feline from your system? ${BOLD}[y/n]:${RESET} "
read -r ANSWER
[[ "$ANSWER" =~ ^[Yy]$ ]] || { echo -e "${DIM}Cancelled.${RESET}"; echo ""; exit 0; }
echo ""

# ── Clean up lock watchdog and data ───────────────────────────────────────────
WATCHDOG_PLIST="$HOME/Library/LaunchAgents/com.feline.lock.watchdog.plist"
WATCHDOG_SCRIPT="$HOME/.feline/lock-watchdog.sh"
LOCK_DIR="$HOME/.feline/locks"

if [[ -f "$WATCHDOG_PLIST" ]]; then
    launchctl unload "$WATCHDOG_PLIST" 2>/dev/null || true
    rm -f "$WATCHDOG_PLIST"
    echo -e "  ${GREEN}✓${RESET}  Removed lock watchdog"
fi

# Remove any per-lock expiry agents
for plist in "$HOME/Library/LaunchAgents/com.feline.lock.expire."*.plist; do
    [[ -f "$plist" ]] || continue
    launchctl unload "$plist" 2>/dev/null || true
    rm -f "$plist"
done

[[ -f "$WATCHDOG_SCRIPT" ]] && rm -f "$WATCHDOG_SCRIPT"
[[ -d "$LOCK_DIR" ]] && rm -rf "$LOCK_DIR" && echo -e "  ${GREEN}✓${RESET}  Removed lock data"

# ── Remove ─────────────────────────────────────────────────────────────────────
ERRORS=0

for bin in "${BINS[@]}"; do
    path="$BINDIR/$bin"
    if [[ -f "$path" ]]; then
        if rm -f "$path" 2>/dev/null; then
            echo -e "  ${GREEN}✓${RESET}  Removed $path"
        else
            # Try with sudo if permission denied
            echo -e "  ${YELLOW}↑${RESET}  $path requires elevated permission"
            if sudo rm -f "$path" 2>/dev/null; then
                echo -e "  ${GREEN}✓${RESET}  Removed $path"
            else
                echo -e "  ${RED}✗${RESET}  Could not remove $path"
                ERRORS=$(( ERRORS + 1 ))
            fi
        fi
    fi
done

if [[ -d "$LIBDIR" ]]; then
    if rmdir "$LIBDIR" 2>/dev/null || rm -rf "$LIBDIR" 2>/dev/null; then
        echo -e "  ${GREEN}✓${RESET}  Removed $LIBDIR"
    else
        sudo rm -rf "$LIBDIR" 2>/dev/null && echo -e "  ${GREEN}✓${RESET}  Removed $LIBDIR" || {
            echo -e "  ${RED}✗${RESET}  Could not remove $LIBDIR"
            ERRORS=$(( ERRORS + 1 ))
        }
    fi
fi

echo ""

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}feline has been removed.${RESET}"
else
    echo -e "${YELLOW}Finished with $ERRORS error(s).${RESET}"
    echo -e "${DIM}You may need to manually remove remaining files.${RESET}"
fi

echo ""
