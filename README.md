# 🧺 DropBasket

> **Floating drag-and-drop basket companion for AeroSpace on macOS.**  
> Effortlessly collect files, switch AeroSpace virtual workspaces, and drag/copy/move them to your target application or directory.

* **Author:** [lalitaalaalitah](https://github.com/lalitaalaalitah)
* **Website:** [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)
* **GitHub Profile:** [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)
* **Version:** `1.0.0`

---

## 💡 Overview

When using tiling window managers like [AeroSpace](https://github.com/nikitabobko/AeroSpace) on macOS, moving files between windows and virtual workspaces is often awkward: dragging a file from Finder in Workspace `1`, switching to Workspace `5` via keyboard shortcuts, and dropping it into VSCode or Terminal often fails because standard drag sessions cancel when switching spaces.

**DropBasket** solves this elegantly:
1. Select items in Finder (or any app) and begin dragging them.
2. **Gently shake your mouse cursor back and forth while dragging.**
3. DropBasket immediately pops up adjacent to your cursor.
4. Drop your files into the basket.
5. Switch to any AeroSpace workspace (e.g. `Alt+1` .. `Alt+9` or your custom keys) — **the basket stays floating on top across all workspaces**.
6. Drag your files out into Finder, Terminal, VSCode, Slack, or any destination!
7. Once cleared or dragged out, the basket automatically hides, ready for your next shake gesture.

---

## ✨ Features

- **🖱️ Shake-to-Summon Gesture:**
  - Hidden by default; only summons when you shake the cursor while dragging files.
  - Also detects mouse shakes when files are selected in Finder.
  - Three configurable sensitivity profiles: `Low`, `Medium` (default), and `High`.
- **🚀 AeroSpace First-Class Citizen:**
  - Built with an `NSPanel` configured with `.canJoinAllSpaces`, `.stationary`, `.ignoresCycle`, and `.fullScreenAuxiliary`.
  - Automatically avoids AeroSpace's tiling engine — never gets split, tiled, or hidden when switching workspaces.
- **📦 Drag All or Individual Items:**
  - Drag individual files out to any destination.
  - Drag **all files at once** using the dedicated "Drag All" button.
- **🔄 Copy & Move Modes:**
  - Toggle between **Copy** mode (preserves source files) and **Move** mode (clears source files upon transfer).
  - Integrated "Move to..." directory picker.
  - "Copy to Clipboard" button (`Cmd+V` paste into Finder or text).
  - "Copy Paths" for terminal users.
- **👁️ Quick Look Preview:**
  - Highlight any item and press `Space` (or click 👁) for native macOS Quick Look previews.
  - "Reveal in Finder" (↗) button.
- **💻 Full Command-Line Interface (CLI):**
  - Control DropBasket from WezTerm, Alacritty, Kitty, or Terminal:
    `dropbasket add file.txt`, `dropbasket show`, `dropbasket list`, etc.
- **🍸 Menu Bar Status Item:**
  - Optional menu bar tray item with one-click actions, sensitivity configuration, and AeroSpace workspace status.
- **🎨 Modern macOS Aesthetic:**
  - Frosted glass HUD with vibrant translucency, responsive hover states, audio feedback, and smooth spring animations.

---

## 🛠️ Installation

### Quick Install (Automated)

Clone the repository and run:

```bash
make install
```

This will:
1. Compile the native release binary using Swift 6.
2. Package `DropBasket.app` with icons and metadata.
3. Install `DropBasket.app` into `~/Applications/`.
4. Install the `dropbasket` command-line utility into `~/.local/bin/`.

### Manual Build

```bash
# Build release binary and app bundle
make app

# Run unit tests
make test
```

---

## ⚙️ AeroSpace Configuration

DropBasket uses macOS accessory panels configured with `.canJoinAllSpaces`. By default, AeroSpace ignores accessory panels and allows them to float across all workspaces.

If you wish to explicitly enforce floating in your AeroSpace configuration, add the following to `~/.config/aerospace/aerospace.toml`:

```toml
[[on-window-detected]]
if.app-id = 'com.lalitaalaalitah.DropBasket'
run = 'layout floating'
```

---

## 🖥️ Command-Line Interface (CLI)

DropBasket includes a command-line tool `dropbasket`:

```bash
# Display version and author metadata
dropbasket --version

# Show help
dropbasket --help

# Add files or folders from terminal into the floating basket
dropbasket add ~/Downloads/document.pdf ~/Pictures/screenshot.png

# Show or hide the basket
dropbasket show
dropbasket hide

# List files currently in the basket
dropbasket list

# Check daemon status
dropbasket status

# Clear all items from the basket
dropbasket clear
```

---

## 🔒 Permissions

DropBasket requires macOS **Accessibility** permission in order to monitor mouse drag movements and detect the shake gesture globally:
1. On first launch, macOS will prompt to grant Accessibility permissions in **System Settings > Privacy & Security > Accessibility**.
2. Enable `DropBasket` (or your terminal emulator if running from CLI).

---

## 🧪 Testing

Run the included automated test suite:

```bash
make test
```

Tests cover:
- Reversal-based shake detection algorithm accuracy (ensuring straight drags do not trigger).
- Dynamic stroke sensitivity thresholds.
- File model deduplication and metadata calculation.
- Metadata and versioning compliance.

---

## 📄 License

Created by [lalitaalaalitah](https://github.com/lalitaalaalitah). Distributed for personal and community productivity with AeroSpace.
