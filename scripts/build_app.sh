#!/usr/bin/env bash
#
# build_app.sh - Build and package DropBasket.app
#
# Author: lalitaalaalitah
# Website: https://www.lalitaalaalitah.com
# GitHub Profile: https://github.com/lalitaalaalitah
#

__version__="1.0.0"

if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "================================================================================"
    echo "  build_app.sh v${__version__}"
    echo "  Author: lalitaalaalitah"
    echo "  Website: https://www.lalitaalaalitah.com"
    echo "  GitHub Profile: https://github.com/lalitaalaalitah"
    echo "================================================================================"
    exit 0
fi

set -e

DIR="$(cd "$(dirname "${BASHASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$DIR"

echo "==> Building DropBasket in release mode..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/DropBasket"
APP_DIR="build/DropBasket.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Packaging into ${APP_DIR}..."
rm -rf "build"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary
cp "${BIN_PATH}" "${MACOS_DIR}/DropBasket"
chmod +x "${MACOS_DIR}/DropBasket"

# Copy Info.plist
cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Copy Icon if exists
if [[ -f "Resources/AppIcon.icns" ]]; then
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Ad-hoc code signing for local execution
echo "==> Ad-hoc signing bundle..."
codesign --force --deep -s - "${APP_DIR}" 2>/dev/null || true

# Create CLI convenience script/wrapper in build/
cat << 'EOF' > build/dropbasket
#!/usr/bin/env bash
# DropBasket CLI wrapper
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BIN="${DIR}/DropBasket.app/Contents/MacOS/DropBasket"

if [[ -f "${APP_BIN}" ]]; then
    exec "${APP_BIN}" "$@"
elif [[ -f "/Applications/DropBasket.app/Contents/MacOS/DropBasket" ]]; then
    exec "/Applications/DropBasket.app/Contents/MacOS/DropBasket" "$@"
elif [[ -f "${HOME}/Applications/DropBasket.app/Contents/MacOS/DropBasket" ]]; then
    exec "${HOME}/Applications/DropBasket.app/Contents/MacOS/DropBasket" "$@"
else
    echo "Error: DropBasket binary not found." >&2
    exit 1
fi
EOF
chmod +x build/dropbasket

echo "==> Successfully created ${APP_DIR} and build/dropbasket"
