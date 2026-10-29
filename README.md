# 🧺 DropBasket

> **Floating drag-and-drop basket companion for AeroSpace on macOS.**  
> Effortlessly collect files, switch AeroSpace virtual workspaces, and drag/copy/move them to your target application or directory. Styled in the beautiful **Catppuccin Mocha** palette.

* **Author:** [lalitaalaalitah](https://github.com/lalitaalaalitah)
* **Website:** [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)
* **GitHub Profile:** [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)
* **Version:** `1.0.0`

---

## 💡 Overview

When using tiling window managers like [AeroSpace](https://github.com/nikitabobko/AeroSpace) on macOS, moving files between windows and virtual workspaces is often awkward: dragging a file from Finder in Workspace `1`, switching to Workspace `5` via keyboard shortcuts, and dropping it into VSCode or Terminal often fails because standard drag sessions cancel when switching spaces.

**DropBasket** solves this elegantly:
1. Select items in Finder (or any app) and begin dragging them.
2. **Gently flick your wrist to shake your cursor.**
3. DropBasket immediately appears **centered directly under your cursor**, so you can drop with **zero extra movement** simply by releasing the mouse button!
4. By default, items drop as **Copy** (as macOS standard). Hold **`⌘` (Command)** while dropping to perform a **Move**!
5. After dropping, see rich file metadata: name, extension badge, file kind, formatted size, relative modification date, parent folder, and operation badge (`[COPY]` or `[⌘ MOVE]`).
6. Switch to any AeroSpace workspace (e.g. `Alt+1` .. `Alt+9` or your custom keys) — **the basket stays pinned on top above everything across all workspaces**.
7. Drag your files out into Finder, Terminal, VSCode, Slack, or any destination!

---

## 🎨 Catppuccin Mocha Themed

Styled with the official **Catppuccin Mocha** colorway:
* **Background:** Base (`#1e1e2e`) with translucent glass effect and subtle Surface1 border.
* **Title & Accents:** Mauve (`#cba6f7`) and Lavender (`#b4befe`).
* **Workspaces:** Sky (`#89dceb`) pill indicator showing your active AeroSpace workspace.
* **Item Cards:** Surface0 (`#313244`) with Surface1 (`#45475a`) interactive hover states.
* **Badges:** Teal (`#94e2d5`) for `[COPY]`, Peach (`#fab387`) for `[⌘ MOVE]`, Sapphire (`#74c7ec`) for extension tags.
* **Action Buttons:** Blue (`#89b4fa`) for Drag All, Red (`#f38ba8`) for Clear/Close.

---

## ✨ Key Features

- **🚀 System LaunchAgent Service:**
  - Runs in the background independently as a native macOS `LaunchAgent` service (`~/Library/LaunchAgents/com.lalitaalaalitah.DropBasket.plist`).
  - No need to keep a terminal window (WezTerm, Alacritty, Kitty) open or run with `&`.
  - Automatically starts on login and remains persistent across your entire macOS session.
- **🖼️ Native App Icon:**
  - Bundled with a custom high-resolution Retina `AppIcon.icns`, fully integrated with Finder, Dock, Spotlight, and LaunchServices.
- **🖱️ Effortless Omnidirectional Shake-to-Summon:**
  - **Kinematic Sliding-Window & Vector Turnaround Engine:** Replaces fragile axis-split detection with 2D vector kinematics. Works smoothly across horizontal, vertical, diagonal (45°), elliptical, and orbital wrist wiggles with zero diagonal blindness.
  - **Sub-Pixel Noise Filtering:** Sub-pixel optical sensor tremor and trackpad micro-jitter (< 1.0 px) are automatically filtered without resetting accumulated strokes.
  - **Zero-Latency Summoning:** Triggers immediately on a natural ~1-centimeter flick (just 2 quick reversals or 26px total path) in < 0.3s.
  - **Centered Drop Target:** The window appears centered directly over your cursor — release the mouse button right there to drop without moving your arm across the screen.
- **📌 Guaranteed Stays on Top Across AeroSpace Spaces:**
  - Configured with `level = .popUpMenu` and `hidesOnDeactivate = false`.
  - Conforms to `.canJoinAllSpaces`, `.stationary`, `.ignoresCycle`, and `.fullScreenAuxiliary`.
  - Pinned on top of all tiled windows, full screen windows, and virtual workspaces. Never gets hidden when clicking other applications.
- **🔄 Default Copy, ⌘+Drop for Move:**
  - Releasing mouse without modifiers defaults to standard macOS **Copy**.
  - Holding **`⌘` (Command)** while dropping triggers **Move** mode (highlighting the drop zone in Catppuccin Peach).
  - Individual items display dynamic `[COPY]` or `[⌘ MOVE]` badges that can be clicked to toggle at any time.
- **📋 Rich Metadata in Basket:**
  - High-res file icon and uppercase extension pill.
  - File name (bold, middle-truncated, legible).
  - Exact file kind (e.g. `Portable Document Format`, `PNG Image`, `Swift Source Code`, `Folder`).
  - Human-readable file size (e.g. `14.2 MB`).
  - Relative modification date (e.g. `Today, 4:30 PM`).
  - Parent directory location (e.g. `📁 in Downloads`).
- **🍸 Top Menu Bar Hint & Status Item:**
  - Clean template basket icon in macOS menu bar (`🧺`).
  - Dynamic count badge hint (`🧺 3`) when files are held.
  - One-click popup menu with Show/Hide basket, workspace indicator, clipboard copy, and settings.
- **🛡️ Single-Instance Management:**
  - Running `dropbasket` when already active instantly summons the floating basket near the cursor instead of spawning conflicting processes.
  - Supports `dropbasket stop`, `dropbasket restart`, and `dropbasket status`.
- **📦 Drag All or Individual Items:**
  - Drag individual files out to any destination.
  - Drag **all files at once** using the `📦 Drag All` button.
- **👁️ Quick Look Preview:**
  - Highlight any item and press `Space` (or click `👁`) for native macOS Quick Look previews.
  - "Reveal in Finder" (`↗`) button.
- **💻 Full Command-Line Interface (CLI):**
  - Control DropBasket from any shell: `dropbasket add file.txt`, `dropbasket show`, `dropbasket service status`, etc.

---

## 🛠️ Installation

### Option 1: Standard Makefile (Recommended for Native macOS)

```bash
# Clone the repository and install:
git clone https://github.com/lalitaalaalitah/DropBasket.git
cd DropBasket
make install
```

`make install` automatically:
1. Compiles the native release binary with Swift 6.
2. Packages `DropBasket.app` with icons and Info.plist into `~/Applications/DropBasket.app`.
3. Registers the bundle with macOS LaunchServices.
4. Installs the `dropbasket` CLI to `~/.local/bin/dropbasket`.
5. Installs and starts the `LaunchAgent` background service (`~/Library/LaunchAgents/com.lalitaalaalitah.DropBasket.plist`).

### Option 2: Nix & Nix Flakes (Nix-Darwin / Home Manager)

```bash
# Run directly without installing:
nix run github:lalitaalaalitah/DropBasket

# Install to your user profile:
nix profile install github:lalitaalaalitah/DropBasket
```

#### Nix-Darwin Integration
```nix
# In your system flake.nix:
inputs.dropbasket.url = "github:lalitaalaalitah/DropBasket";

# In your darwin configuration modules:
imports = [ inputs.dropbasket.darwinModules.default ];
services.dropbasket.enable = true;
```

#### Home Manager Integration
```nix
# In your home-manager configuration modules:
imports = [ inputs.dropbasket.homeModules.default ];
services.dropbasket.enable = true;
```

---

## ⚙️ AeroSpace Configuration

DropBasket's accessory panel configuration is automatically ignored by AeroSpace's tiling layout. If you wish to make it explicit in your `~/.config/aerospace/aerospace.toml`, add:

```toml
[[on-window-detected]]
if.app-id = 'com.lalitaalaalitah.DropBasket'
run = 'layout floating'
```

---

## 🖥️ Command-Line Interface (CLI)

```bash
# Display version and author metadata
dropbasket --version

# Summon floating basket near cursor (or start service if stopped)
dropbasket

# Add files or folders from terminal into the floating basket
dropbasket add ~/Downloads/document.pdf ~/Pictures/screenshot.png

# Show or hide the basket
dropbasket show
dropbasket hide

# List files currently in the basket
dropbasket list

# Check daemon and AeroSpace workspace status
dropbasket status

# Clear all items from the basket
dropbasket clear

# Stop or restart the background daemon
dropbasket stop
dropbasket restart

# Background Service Management (LaunchAgent):
dropbasket service status      # Check if background service is running
dropbasket service start       # Start background service
dropbasket service stop        # Stop background service
dropbasket service restart     # Restart background service
dropbasket service install     # Reinstall LaunchAgent service
dropbasket service uninstall   # Remove LaunchAgent service
```

---

## 🔒 Permissions

DropBasket requires macOS **Accessibility** permission in order to monitor mouse drag movements globally:
1. On first launch, macOS will prompt to grant Accessibility permissions in **System Settings > Privacy & Security > Accessibility**.
2. Enable `DropBasket` (and your terminal emulator if running CLI directly).

---

## 📄 License

Created by [lalitaalaalitah](https://github.com/lalitaalaalitah). Distributed for personal and community productivity with AeroSpace.
