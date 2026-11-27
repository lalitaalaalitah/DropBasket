# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-11-27

### Fixed
- **Reverted Experimental Shake Kinematics**: Restored original, proven shake detection algorithms and sensitivity thresholds in `ShakeDetector.swift`, `Settings.swift`, and `AeroSpaceHelper.swift` to eliminate spurious triggers and erratic popup behavior.
- **Isolated Text Selection Immunity**: Retained exclusively the targeted pasteboard change-count tracking and file-type validation in `EventTapManager.swift`, `BasketPanel.swift`, and `BasketViewController.swift` that prevents DropBasket from popping up when selecting text or dragging text snippets.
- **Home Manager LaunchAgent Detection**: Retained LaunchAgent and binary path discovery in `ServiceManager.swift` for seamless Nix and Home Manager service management.

## [1.3.0] - 2026-11-27

### Fixed
- **Eliminated False Summons on Free Mouse Movement**: Removed `mouseMoved` tracking and disabled bare cursor movement summoning (`triggerOnFinderSelection`). DropBasket strictly and exclusively responds when a user is actively holding down the mouse button and dragging files.
- **Accidental Drag Trigger Prevention**: Calibrated stroke amplitude threshold to `minStrokeDistance = 14.0px` and `minTotalPath = 42.0px`, ensuring natural 3–6px hand wobbles during ordinary file drags or window movements are never mistaken for intentional shakes.
- **Sharp Reversal Angle Filtering**: Enforced acute vector turnaround verification (`cosAngle < -0.42`, angle > 115°), ensuring gentle curves, L-turns, and directional adjustments do not register as reversals.
- **Strict Drag Session Enforcement**: Verified that `isDragging` and `isSystemFileDragInProgress()` are required prior to any panel summon, completely preventing spurious popups during text selection, window moving, or slider adjustments.

## [1.2.0] - 2026-11-27

### Fixed
- **Instantaneous Shake Detection**: Replaced global displacement ratio and historical sample buffer with localized stroke turnaround kinematics (`StrokeReversal`), eliminating detection delay and allowing the basket to appear on the very first natural flick.
- **Drag-to-Shake Responsiveness**: Removed drag history contamination so shaking the cursor immediately after a long linear drag across the screen triggers in < 150ms without waiting for prior drag coordinates to expire.
- **Zero-Latency In-Memory Drag Validation**: Validated drag session contents using fast in-memory UTI types (`.fileURL`, `public.file-url`, `NSFilenamesPboardType`, `com.apple.finder.node`), eliminating blocking pasteboard object deserialization during modal drag loops.
- **Sensitivity & Time Window Calibration**: Tuned default sensitivity thresholds (`minStrokeDistance: 5.0px`, `minTotalPath: 18.0px`, `timeWindow: 0.65s`, `cooldown: 0.35s`) for effortless, fluid cursor wiggling on both trackpads and mice.
- **Main-Thread Presentation Optimization**: Added result caching to `AeroSpaceHelper.getFocusedWorkspace()` and trimmed window presentation animation to 0.08s for zero-latency appearance.

## [1.1.0] - 2026-11-27

### Fixed
- **Text Selection Immunity**: Prevent DropBasket from falsely popping up when selecting text or dragging selected text snippets in any editor, browser, terminal, or document.
- **System Drag Session Validation**: Integrated `mouseDownDragChangeCount` tracking against `NSPasteboard.Name.drag.changeCount` in `EventTapManager`. Verified that a genuine system drag session is in progress before evaluating cursor shake.
- **Payload File Filtering**: Ensured `hasFileContent(in:)` strictly requires file URLs (`.fileURL`, `public.file-url`, `NSFilenamesPboardType`, or promised file nodes), actively rejecting text payloads (`public.utf8-plain-text`, `NSStringPboardType`).
- **Drop Destination Hardening**: Removed `.string` and `.URL` from `registerForDraggedTypes` in `BasketPanel` and `BasketViewController`, ensuring DropBasket exclusively accepts filesystem items.
- **Dropped Path String Fallback Removal**: Removed text fallback conversion in `extractURLs` so raw text lines cannot be converted into fake files.
- **Home Manager Service Detection**: Enhanced `ServiceManager.status()` and `findAppBinaryPath()` to automatically detect Home Manager managed LaunchAgent (`org.nix-community.home.dropbasket.plist`) and Nix store binary paths.

## [1.0.0] - 2026-10-29

### Added
- Initial public release of DropBasket for macOS with AeroSpace companion support.
- Floating `NSPanel` using `.canJoinAllSpaces` and `popUpMenuWindow` level to remain visible across all AeroSpace workspaces.
- Catppuccin Mocha aesthetic with rich file metadata badges and item counts.
- Omnidirectional 2D vector kinematics shake detection engine.
- LaunchAgent background service manager (`dropbasket service [install|uninstall|start|stop|restart|status]`).
- Nix Flake and Nix-Darwin / Home Manager declarative modules.
- GitHub Actions CI and Automated Release workflows.
