//
//  BasketPanel.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa

@MainActor
public class BasketPanel: NSPanel {
    public static let shared = BasketPanel()

    private var autoHideTimer: Timer?
    private let basketVC = BasketViewController()

    private init() {
        let defaultRect = NSRect(x: 200, y: 200, width: 400, height: 460)
        super.init(
            contentRect: defaultRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.title = Metadata.appName
        self.isFloatingPanel = true
        // High level: popUpMenuWindow stays above everything including AeroSpace tiled windows
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)))
        // Crucial for AeroSpace compatibility:
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        // Never hide on deactivate!
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
        self.becomesKeyOnlyIfNeeded = true
        self.isMovableByWindowBackground = true
        self.hasShadow = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.contentViewController = basketVC
    }

    public func showNear(cursorPoint: CGPoint) {
        cancelAutoHideTimer()
        basketVC.refreshUI()

        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 1080
        let cocoaPoint = NSPoint(x: cursorPoint.x, y: primaryScreenHeight - cursorPoint.y)

        // Find active screen
        let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(cocoaPoint, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens[0]
        let visibleFrame = activeScreen.visibleFrame

        let width: CGFloat = 400
        let height: CGFloat = 460

        // Center horizontally around the cursor, and position cursor directly inside the upper drop area
        var targetX = cocoaPoint.x - (width / 2.0)
        var targetY = cocoaPoint.y - height + 100.0

        // Clamp inside visible frame
        targetX = max(visibleFrame.minX + 12, min(targetX, visibleFrame.maxX - width - 12))
        targetY = max(visibleFrame.minY + 12, min(targetY, visibleFrame.maxY - height - 12))

        setFrame(NSRect(x: targetX, y: targetY, width: width, height: height), display: true)

        if !isVisible {
            alphaValue = 0.0
            orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.14
                animator().alphaValue = 1.0
            }
        } else {
            orderFrontRegardless()
        }
    }

    public func toggleVisibility() {
        if isVisible {
            hideWithFade()
        } else {
            let mouseLoc = NSEvent.mouseLocation
            let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
            let cgPoint = CGPoint(x: mouseLoc.x, y: primaryHeight - mouseLoc.y)
            showNear(cursorPoint: cgPoint)
        }
    }

    public func hideWithFade() {
        cancelAutoHideTimer()
        guard isVisible else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            MainActor.assumeIsolated {
                self.orderOut(nil)
                self.alphaValue = 1.0
            }
        })
    }

    public func startAutoHideTimer() {
        cancelAutoHideTimer()
        // If files are held in the basket, NEVER auto-hide!
        guard BasketModel.shared.isEmpty else { return }

        // Generous delay so the user isn't rushed
        let delay = AppSettings.shared.autoHideDelay
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // Only hide if still empty and mouse is not currently inside the window
                let mouseLoc = NSEvent.mouseLocation
                if BasketModel.shared.isEmpty && !NSMouseInRect(mouseLoc, self.frame, false) {
                    self.hideWithFade()
                }
            }
        }
    }

    public func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return false
    }
}
