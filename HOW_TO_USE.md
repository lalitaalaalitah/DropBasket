# 📖 How to Use DropBasket

> **Complete User Guide for DropBasket & AeroSpace**  
> Author: [lalitaalaalitah](https://github.com/lalitaalaalitah)  
> Website: [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)  
> GitHub Profile: [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)  
> Version: `1.0.0`

---

## 🚀 Quick Start Guide

### 1. Launching the App

You can launch DropBasket in one of two ways:

- **Via Finder / Spotlight / Launchpad:**
  Open `DropBasket` from `~/Applications` or `/Applications`.
- **Via Terminal / Shell:**
  ```bash
  dropbasket
  ```
  *(Or `open -a DropBasket`)*

When launched, DropBasket runs quietly in the background without cluttering your Dock. You will notice a small 🧺 basket icon in your macOS menu bar.

---

## 🎯 Core Workflow: Inter-Workspace Drag & Drop with AeroSpace

### Scenario
You are in **AeroSpace Workspace `1`** (Finder / Browser). You want to move three files into **AeroSpace Workspace `5`** (VSCode / Terminal project folder).

### Step-by-Step Instructions:

1. **Select Your Files:**
   In Finder, select the files or folders you want to move.

2. **Start Dragging & Shake Your Cursor:**
   - Click and hold the left mouse button to start dragging the files.
   - While holding the mouse button, **gently shake the mouse cursor back and forth 2–3 times** (a quick left-right-left movement).
   - **DropBasket instantly pops up right next to your mouse pointer!**

3. **Drop Files into the Basket:**
   - Release the left mouse button over the DropBasket window.
   - You will hear a confirmation chime (`Pop`), and your files will appear in the basket with their names, file sizes, and high-resolution icons.

4. **Switch AeroSpace Workspace:**
   - Press your AeroSpace keyboard shortcut to switch to the destination workspace (e.g. `Alt+5`, `Alt+f`, or your configured workspace binding).
   - **Notice that DropBasket stays floating on your screen.** AeroSpace does not tile it and does not hide it!

5. **Transfer Your Files Out:**
   You now have multiple ways to place your files into the target workspace:
   - **Option A (Drag Any Item):** Click and drag any file from the basket directly into your target Finder window, editor, terminal, or Slack.
   - **Option B (Drag All Items):** Click and drag the **`📦 Drag All`** button in the header to drop all files simultaneously into any folder.
   - **Option C (Clipboard Paste):** Click **`📋`** (Copy All), click inside your target folder in Finder or terminal, and press `Cmd+V`.
   - **Option D (Move To... Dialog):** Click **`Move to...`** at the bottom to choose a destination directory directly.

6. **Auto-Hiding:**
   Once all files have been dragged out or cleared, DropBasket automatically fades away and hides itself until the next time you shake your cursor.

---

## ⚙️ Trigger Options & Gesture Customization

DropBasket provides two summon methods:

### 1. Drag & Shake (Default)
Hold down the left mouse button while dragging files from any application and shake the mouse back and forth. The basket appears next to your cursor. If you release the mouse outside the basket without dropping any files, the empty basket automatically closes after 2.5 seconds.

### 2. Finder Selection Shake
If you have items selected in Finder, you can simply shake your mouse cursor even without dragging. DropBasket will appear and offer a **`Collect Selected Items`** button to grab them in one click.

### Adjusting Shake Sensitivity
Click the 🧺 menu bar icon and open **Shake Sensitivity**:
- **Low:** Requires larger, deliberate hand movements (stroke amplitude $\ge 35\text{px}$, 4 reversals). Best if you have accidental triggers.
- **Medium (Default):** Balanced for everyday usage ($\ge 22\text{px}$, 3 reversals).
- **High:** Very sensitive; requires only slight wrist flicking ($\ge 14\text{px}$, 3 reversals).

---

## 🎛️ Keyboard Shortcuts & Features

| Action | Method |
| :--- | :--- |
| **Summon / Dismiss Basket** | `Ctrl + Option + B` (or via menu bar) |
| **Quick Look Preview** | Select file and press `Space` (or click 👁) |
| **Close / Hide Basket** | Press `Escape` or click `✕` |
| **Reveal in Finder** | Click `↗` icon on any file row |
| **Remove File** | Click `✕` icon on any file row |
| **Toggle Copy vs Move** | Click `Mode: Copy` / `Mode: Move` toggle in footer |

---

## 💻 Terminal & AeroSpace Integration

For keyboard-driven workflows (e.g., using WezTerm, Alacritty, or Ghostty with AeroSpace), the `dropbasket` CLI allows scripting and hotkey actions:

### Adding Files from Terminal
```bash
# Add single or multiple files to the floating basket:
dropbasket add ~/Downloads/dataset.csv ~/Documents/report.pdf

# Or add files directly:
dropbasket ~/Pictures/*.png
```
The basket will immediately appear with the added files ready for you to switch to another workspace.

### Checking Basket Contents
```bash
dropbasket list
```
Output:
```text
ITEMS (2):
dataset.csv (14.2 MB) -> /Users/username/Downloads/dataset.csv
report.pdf (3.1 MB) -> /Users/username/Documents/report.pdf
```

### Checking Daemon Status
```bash
dropbasket status
```
Output:
```text
STATUS running=true visible=true items=2 workspace=a
```

### Clearing the Basket
```bash
dropbasket clear
```

---

## 🔧 Troubleshooting & FAQ

### 1. The basket doesn't appear when shaking:
- **Check Accessibility Permissions:** macOS requires Accessibility access to detect mouse drags globally. Open **System Settings > Privacy & Security > Accessibility** and ensure `DropBasket` (and your terminal if debugging) is checked.
- **Sensitivity:** Try setting the sensitivity to **High** from the menu bar to see if your shake speed requires lighter thresholds.

### 2. AeroSpace tiles or moves the basket:
- DropBasket runs as an `NSPanel` with `.canJoinAllSpaces` and `nonactivatingPanel`, which AeroSpace ignores by default.
- If you have an aggressive catch-all rule in `~/.config/aerospace/aerospace.toml`, add an explicit floating override:
  ```toml
  [[on-window-detected]]
  if.app-id = 'com.lalitaalaalitah.DropBasket'
  run = 'layout floating'
  ```

### 3. How to quit DropBasket:
Click the 🧺 menu bar icon and select **Quit DropBasket** (or press `Cmd+Q` from the menu).

---

## 📞 Support & Community

* Author: **lalitaalaalitah**
* Website: [https://www.lalitaalaalitah.com](https://www.lalitaalaalitah.com)
* GitHub: [https://github.com/lalitaalaalitah](https://github.com/lalitaalaalitah)
