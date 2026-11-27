# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-11-27

### Fixed
- **Text Selection Immunity**: Prevent DropBasket from falsely popping up when selecting text or dragging selected text snippets in any editor, browser, terminal, or document.
- **System Drag Session Validation**: Integrated `mouseDownDragChangeCount` tracking against `NSPasteboard.Name.drag.changeCount` in `EventTapManager`. Verified that a genuine system drag session is in progress before evaluating cursor shake.
- **Payload File Filtering**: Ensured `hasFileContent(in:)` strictly requires file URLs (`.fileURL`, `public.file-url`, `NSFilenamesPboardType`, or promised file nodes), actively rejecting text payloads (`public.utf8-plain-text`, `NSStringPboardType`).
- **Drop Destination Hardening**: Removed `.string` and `.URL` from `registerForDraggedTypes` in `BasketPanel` and `BasketViewController`, ensuring DropBasket exclusively accepts filesystem items.
- **Dropped Path String Fallback Removal**: Removed text fallback conversion in `extractURLs` so raw text lines cannot be converted into fake files.

## [1.0.0] - 2026-10-29

### Added
- Initial public release of DropBasket for macOS with AeroSpace companion support.
- Floating `NSPanel` using `.canJoinAllSpaces` and `popUpMenuWindow` level to remain visible across all AeroSpace workspaces.
- Catppuccin Mocha aesthetic with rich file metadata badges and item counts.
- Omnidirectional 2D vector kinematics shake detection engine.
- LaunchAgent background service manager (`dropbasket service [install|uninstall|start|stop|restart|status]`).
- Nix Flake and Nix-Darwin / Home Manager declarative modules.
- GitHub Actions CI and Automated Release workflows.
