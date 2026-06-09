#!/usr/bin/env bash
# ── Second Brain — Desktop Shortcut Installer ─────────────────────────────────
# Run once after setup:  bash install-launcher.sh
# Creates a double-clickable launcher on your Desktop and in the app menu.

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
RUN_SCRIPT="$PROJECT_DIR/run.sh"
ICON="$PROJECT_DIR/static/icon.png"
DESKTOP_FILE="$HOME/Desktop/SecondBrain.desktop"
APP_DIR="$HOME/.local/share/applications"
APP_FILE="$APP_DIR/second-brain.desktop"

# Use a fallback icon if none exists
if [ ! -f "$ICON" ]; then
  ICON="utilities-terminal"   # built-in system icon
fi

ENTRY="[Desktop Entry]
Version=1.0
Type=Application
Name=Second Brain
Comment=Local AI document assistant
Exec=bash -c 'cd \"$PROJECT_DIR\" && bash run.sh; exec bash'
Icon=$ICON
Terminal=false
Categories=Office;Education;Utility;
StartupNotify=true
"

echo ""
echo -e "${CYAN}${BOLD}  Installing Second Brain launcher...${RESET}"
echo ""

# Desktop shortcut
mkdir -p "$HOME/Desktop"
echo "$ENTRY" > "$DESKTOP_FILE"
chmod +x "$DESKTOP_FILE"

# If on GNOME/Ubuntu, mark it as trusted so it's executable
if command -v gio &>/dev/null; then
  gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
fi

echo -e "${GREEN}  ✓ Desktop shortcut created:${RESET} ~/Desktop/SecondBrain.desktop"

# App menu entry
mkdir -p "$APP_DIR"
echo "$ENTRY" > "$APP_FILE"
chmod +x "$APP_FILE"
echo -e "${GREEN}  ✓ App menu entry created${RESET}"

# Refresh desktop database
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database "$APP_DIR" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}${BOLD}  Done!${RESET} You can now double-click ${BOLD}Second Brain${RESET} on your Desktop"
echo -e "  (or search for it in your app menu) to launch without a terminal."
echo ""
