//
//  AppDelegate.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import ApplicationServices

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Set accessory policy so DropBasket doesn't clutter the macOS Dock
        NSApp.setActivationPolicy(.accessory)

        // Check Accessibility Permissions
        checkAccessibilityPermissions()

        // Setup Event Tap for mouse shake detection
        setupEventTap()

        // Setup Menu Bar Icon
        MenuBarController.shared.setup()

        // Setup IPC Server for CLI commands
        IPCService.shared.startServer()

        print("[\(Metadata.appName)] v\(Metadata.appVersion) running in background.")
        print("[\(Metadata.appName)] Shake cursor while dragging files to summon the basket.")
    }

    public func applicationWillTerminate(_ notification: Notification) {
        EventTapManager.shared.stop()
        IPCService.shared.stopServer()
    }

    private func checkAccessibilityPermissions() {
        if !AXIsProcessTrusted() {
            print("[\(Metadata.appName)] Warning: Accessibility permission not granted yet.")
            let options = ["prompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    private func setupEventTap() {
        EventTapManager.shared.onShakeDetected = { point, isDragging in
            if isDragging {
                BasketPanel.shared.showNear(cursorPoint: point)
            } else {
                // Shaken with Finder selection
                let sel = FinderHelper.shared.getSelectedURLs()
                if !sel.isEmpty {
                    BasketPanel.shared.showNear(cursorPoint: point)
                }
            }
            MenuBarController.shared.rebuildMenu()
        }

        EventTapManager.shared.onDragEnded = { _ in
            if BasketModel.shared.isEmpty {
                BasketPanel.shared.startAutoHideTimer()
            }
        }

        let success = EventTapManager.shared.start()
        if !success {
            print("[\(Metadata.appName)] Failed to start event tap. Trying session tap fallback...")
        }
    }
}
