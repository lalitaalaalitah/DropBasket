# 📖 How to Use DropBasket

> **Complete User Guide for DropBasket & AeroSpace**  
> Author: [lalitaalaalitah](https://github.com/lalitaalaalitah)  
> Website: [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)  
> GitHub Profile: [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)  
> Version: `1.0.0` • Styled with **Catppuccin Mocha**

---

## 🚀 Quick Start Guide

### 1. Launching DropBasket

Launch DropBasket using either:
- **Application:** Launch `DropBasket` from `~/Applications` or Spotlight.
- **Terminal:**
  ```bash
  dropbasket
  ```

DropBasket runs in the background as an accessory panel (`LSUIElement`) with a 🧺 menu bar icon.

---

## 🎯 The Effortless Drop Workflow

### Step 1: Select & Start Dragging
Select files in Finder, Safari, or any app, and begin dragging them.

### Step 2: Gentle Wrist Shake
- While holding the left mouse button, **gently flick your wrist back and forth**.
- Thanks to the optimized sensitivity threshold (just 8px movement and 2 directional reversals), the slightest quick wiggle instantly triggers summon.
- **Notice the positioning:** DropBasket appears **directly under your cursor**.

### Step 3: Zero-Movement Drop (Copy vs ⌘ Move)
- **Standard Copy:** Simply release the left mouse button right where you are. The files drop into the basket.
- **Cmd+Drop for Move:** Hold down the **`⌘` (Command)** key as you release the mouse button. The drop border turns Catppuccin Peach (`#fab387`), and the files are tagged for a **Move** operation (`[⌘ MOVE]`).

### Step 4: Inspect Rich File Metadata
Once dropped, each file in the basket displays:
* **Icon & Extension Pill:** 38x38 high-res system icon with a mono-spaced badge (`[PDF]`, `[PNG]`, `[SWIFT]`, `[DIR]`).
* **File Name:** Full legible name in Catppuccin Text (`#cdd6f4`).
* **Kind & Size:** Detailed localized type (e.g. `Portable Document Format • 14.2 MB`) in Catppuccin Subtext0 (`#a6adc8`).
* **Directory & Modification Date:** Parent folder and human-friendly date (`📁 in Downloads • Today, 04:30`) in Catppuccin Overlay1 (`#7f849c`).
* **Mode Badge:** Clickable `[COPY]` (Teal) or `[⌘ MOVE]` (Peach) pill to toggle between Copy and Move at any time.

### Step 5: Switch AeroSpace Workspaces
- Press your AeroSpace workspace shortcut (e.g. `Alt+2`, `Alt+f`, `Alt+v`).
- **DropBasket stays pinned on top of all windows and workspaces.** It uses `level = .popUpMenu` and `hidesOnDeactivate = false`, so it will never disappear or hide when switching spaces or activating other apps.

### Step 6: Transfer Out
- **Individual File:** Click and drag any file row directly into Finder, VSCode, Slack, or Terminal.
- **All Files at Once:** Click and drag the **`📦 Drag All`** button in the header.
- **Clipboard:** Click **`📋`** to copy files, switch to your target folder, and press `Cmd+V`.
- **Move to... Folder:** Click **`Move to...`** in the footer to choose a folder dialog.

---

## 🎨 Catppuccin Mocha Visual Indicators

* **Teal (`#94e2d5`):** Standard Copy operations.
* **Peach (`#fab387`):** Command+Drop Move operations.
* **Mauve (`#cba6f7`):** Active drop target border and header title.
* **Sky (`#89dceb`):** AeroSpace workspace indicator (`[Space: a]`).
* **Blue (`#89b4fa`):** "Drag All" button and action highlights.
* **Red (`#f38ba8`):** Remove item and clear basket actions.

---

## 🎛️ Keyboard Shortcuts & Controls

| Shortcut / Action | Function |
| :--- | :--- |
| **Shake Cursor while Dragging** | Summon DropBasket directly under cursor |
| **Hold `⌘` while Dropping** | Trigger Move mode instead of default Copy |
| **Spacebar** | Quick Look preview for selected item |
| **Escape** | Dismiss / Hide basket |
| **Click `[COPY]` / `[⌘ MOVE]`** | Toggle individual item transfer mode |
| **`Ctrl + Option + B`** | Manually toggle basket visibility |

---

## 💻 CLI Commands for Terminal Users

```bash
# Add files from terminal:
dropbasket add ~/Downloads/document.pdf

# List files and metadata in basket:
dropbasket list

# Check status:
dropbasket status

# Show or hide:
dropbasket show
dropbasket hide

# Clear basket:
dropbasket clear
```

---

## 📞 Support & Community

* Author: **lalitaalaalitah**
* Website: [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)
* GitHub: [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)
