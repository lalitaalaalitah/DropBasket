#!/usr/bin/env bash
#
# install.sh - Install DropBasket.app, dropbasket CLI, and LaunchAgent service
#
# Author: lalitaalaalitah
# Website: https://www.lalitaalaalitah.com
# GitHub Profile: https://github.com/lalitaalaalitah
#

__version__="1.0.0"

if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "================================================================================"
    echo "  install.sh v${__version__}"
    echo "  Author: lalitaalaalitah"
    echo "  Website: https://www.lalitaalaalitah.com"
    echo "  GitHub Profile: https://github.com/lalitaalaalitah"
    echo "================================================================================"
    exit 0
fi

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "==> Building DropBasket..."
./scripts/build_app.sh

APP_SRC="build/DropBasket.app"
DEST_APPS="${HOME}/Applications"
DEST_BIN="${HOME}/.local/bin"

mkdir -p "${DEST_APPS}"
mkdir -p "${DEST_BIN}"

echo "==> Installing DropBasket.app to ${DEST_APPS}..."
rm -rf "${DEST_APPS}/DropBasket.app"
cp -R "${APP_SRC}" "${DEST_APPS}/"
touch "${DEST_APPS}/DropBasket.app"

# Register with macOS LaunchServices so Finder and Dock display the AppIcon immediately
LS_REGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -f "${LS_REGISTER}" ]]; then
    "${LS_REGISTER}" -f "${DEST_APPS}/DropBasket.app" 2>/dev/null || true
fi

echo "==> Installing dropbasket CLI to ${DEST_BIN}..."
cp "build/dropbasket" "${DEST_BIN}/dropbasket"
chmod +x "${DEST_BIN}/dropbasket"

echo "==> Setting up DropBasket LaunchAgent background service..."
"${DEST_BIN}/dropbasket" service install || true

echo "================================================================================"
echo "  DropBasket installed successfully!"
echo "  App: ${DEST_APPS}/DropBasket.app"
echo "  CLI: ${DEST_BIN}/dropbasket"
echo "  Service: ~/Library/LaunchAgents/com.lalitaalaalitah.DropBasket.plist"
echo "================================================================================"
echo ""
echo "DropBasket is now running in the background as a system service!"
echo "Look for the 🧺 basket icon in your macOS top menu bar."
echo ""
echo "Useful commands:"
echo "  dropbasket              # Bring basket to cursor"
echo "  dropbasket service status   # Check service state"
echo "  dropbasket service stop     # Stop background service"
echo "  dropbasket service start    # Start background service"
echo ""
