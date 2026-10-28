#!/usr/bin/env bash
#
# install.sh - Install DropBasket.app and dropbasket CLI
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

echo "==> Installing dropbasket CLI to ${DEST_BIN}..."
cp "build/dropbasket" "${DEST_BIN}/dropbasket"
chmod +x "${DEST_BIN}/dropbasket"

echo "================================================================================"
echo "  DropBasket installed successfully!"
echo "  App: ${DEST_APPS}/DropBasket.app"
echo "  CLI: ${DEST_BIN}/dropbasket"
echo "================================================================================"
echo ""
echo "To launch DropBasket, run:"
echo "  open -a DropBasket"
echo "  or simply: dropbasket"
echo ""
