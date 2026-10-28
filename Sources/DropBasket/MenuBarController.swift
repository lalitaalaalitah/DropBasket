//
//  MenuBarController.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa

@MainActor
public class MenuBarController: NSObject {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem?.button {
            btn.title = "🧺"
            btn.toolTip = "\(Metadata.appName): Shake while dragging to summon basket"
        }
        rebuildMenu()
    }

    public func rebuildMenu() {
        menu.removeAllItems()

        // App Header
        let titleItem = NSMenuItem(title: "\(Metadata.appName) v\(Metadata.appVersion)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Status
        let count = BasketModel.shared.count
        let statusText = count > 0 ? "Holding \(BasketModel.shared.summaryString)" : "Hidden • Shake mouse to summon"
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Show/Hide
        let toggleItem = NSMenuItem(
            title: BasketPanel.shared.isVisible ? "Hide Basket" : "Show Basket",
            action: #selector(toggleBasket),
            keyEquivalent: "b"
        )
        toggleItem.keyEquivalentModifierMask = [.control, .option]
        toggleItem.target = self
        menu.addItem(toggleItem)

        // Collect Finder
        let finderItem = NSMenuItem(title: "Collect Finder Selection", action: #selector(collectFinder), keyEquivalent: "")
        finderItem.target = self
        menu.addItem(finderItem)

        // Copy files
        let copyItem = NSMenuItem(title: "Copy Basket Files to Clipboard", action: #selector(copyFiles), keyEquivalent: "")
        copyItem.target = self
        copyItem.isEnabled = count > 0
        menu.addItem(copyItem)

        // Clear
        let clearItem = NSMenuItem(title: "Clear Basket", action: #selector(clearBasket), keyEquivalent: "")
        clearItem.target = self
        clearItem.isEnabled = count > 0
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        // Sensitivity submenu
        let sensMenu = NSMenu()
        for sens in ShakeSensitivity.allCases {
            let item = NSMenuItem(title: sens.rawValue, action: #selector(changeSensitivity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = sens
            item.state = (AppSettings.shared.sensitivity == sens) ? .on : .off
            sensMenu.addItem(item)
        }
        let sensItem = NSMenuItem(title: "Shake Sensitivity", action: nil, keyEquivalent: "")
        sensItem.submenu = sensMenu
        menu.addItem(sensItem)

        // Default action submenu
        let actionMenu = NSMenu()
        let copyActionItem = NSMenuItem(title: "Copy (Keep original)", action: #selector(setActionCopy), keyEquivalent: "")
        copyActionItem.target = self
        copyActionItem.state = (!AppSettings.shared.defaultActionIsMove) ? .on : .off
        actionMenu.addItem(copyActionItem)

        let moveActionItem = NSMenuItem(title: "Move (Delete original)", action: #selector(setActionMove), keyEquivalent: "")
        moveActionItem.target = self
        moveActionItem.state = (AppSettings.shared.defaultActionIsMove) ? .on : .off
        actionMenu.addItem(moveActionItem)

        let dragActionItem = NSMenuItem(title: "Default Drop Action", action: nil, keyEquivalent: "")
        dragActionItem.submenu = actionMenu
        menu.addItem(dragActionItem)

        // Finder trigger toggle
        let finderToggle = NSMenuItem(title: "Summon on Finder Selection Shake", action: #selector(toggleFinderTrigger), keyEquivalent: "")
        finderToggle.target = self
        finderToggle.state = AppSettings.shared.triggerOnFinderSelection ? .on : .off
        menu.addItem(finderToggle)

        // Sound effects toggle
        let soundToggle = NSMenuItem(title: "Sound Effects", action: #selector(toggleSound), keyEquivalent: "")
        soundToggle.target = self
        soundToggle.state = AppSettings.shared.soundEffects ? .on : .off
        menu.addItem(soundToggle)

        menu.addItem(NSMenuItem.separator())

        // AeroSpace Status & Helper
        if let ws = AeroSpaceHelper.shared.getFocusedWorkspace() {
            let wsItem = NSMenuItem(title: "AeroSpace Workspace: [\(ws)]", action: nil, keyEquivalent: "")
            wsItem.isEnabled = false
            menu.addItem(wsItem)
        }
        let aeroConfigItem = NSMenuItem(title: "Copy AeroSpace Config Rule", action: #selector(copyAeroSpaceConfig), keyEquivalent: "")
        aeroConfigItem.target = self
        menu.addItem(aeroConfigItem)

        menu.addItem(NSMenuItem.separator())

        // About & Quit
        let aboutItem = NSMenuItem(title: "About \(Metadata.appName)...", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit \(Metadata.appName)", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleBasket() {
        BasketPanel.shared.toggleVisibility()
        rebuildMenu()
    }

    @objc private func collectFinder() {
        let urls = FinderHelper.shared.getSelectedURLs()
        if !urls.isEmpty {
            BasketModel.shared.add(urls: urls)
            BasketPanel.shared.toggleVisibility()
        }
        rebuildMenu()
    }

    @objc private func copyFiles() {
        BasketModel.shared.copyFilesToClipboard()
    }

    @objc private func clearBasket() {
        BasketModel.shared.clear()
        rebuildMenu()
    }

    @objc private func changeSensitivity(_ sender: NSMenuItem) {
        if let sens = sender.representedObject as? ShakeSensitivity {
            AppSettings.shared.sensitivity = sens
            rebuildMenu()
        }
    }

    @objc private func setActionCopy() {
        AppSettings.shared.defaultActionIsMove = false
        rebuildMenu()
    }

    @objc private func setActionMove() {
        AppSettings.shared.defaultActionIsMove = true
        rebuildMenu()
    }

    @objc private func toggleFinderTrigger() {
        AppSettings.shared.triggerOnFinderSelection.toggle()
        rebuildMenu()
    }

    @objc private func toggleSound() {
        AppSettings.shared.soundEffects.toggle()
        rebuildMenu()
    }

    @objc private func copyAeroSpaceConfig() {
        let snippet = AeroSpaceHelper.shared.configSnippet()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet, forType: .string)

        let alert = NSAlert()
        alert.messageText = "AeroSpace Config Copied!"
        alert.informativeText = "The following rule has been copied to your clipboard:\n\n\(snippet)\n\nPaste it into ~/.config/aerospace/aerospace.toml if you want to ensure AeroSpace keeps DropBasket floating."
        alert.runModal()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "\(Metadata.appName) v\(Metadata.appVersion)"
        alert.informativeText = """
        Author: \(Metadata.author)
        Website: \(Metadata.website)
        GitHub Profile: \(Metadata.github)

        DropBasket is a floating shelf companion designed for AeroSpace.
        Shake your mouse while dragging items to summon the basket.
        Switch to any AeroSpace workspace and drag or copy your files out!
        """
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
