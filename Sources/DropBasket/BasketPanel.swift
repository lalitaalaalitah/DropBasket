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
        let defaultRect = NSRect(x: 200, y: 200, width: 360, height: 420)
        super.init(
            contentRect: defaultRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.title = Metadata.appName
        self.isFloatingPanel = true
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) + 2)
        // Crucial for AeroSpace compatibility:
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
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

        let width: CGFloat = 360
        let height: CGFloat = 420

        var targetX = cocoaPoint.x + 20
        var targetY = cocoaPoint.y - (height / 2)

        // If overflowing to right, place on left
        if targetX + width > visibleFrame.maxX {
            targetX = cocoaPoint.x - width - 20
        }

        // Clamp inside visible frame
        targetX = max(visibleFrame.minX + 8, min(targetX, visibleFrame.maxX - width - 8))
        targetY = max(visibleFrame.minY + 8, min(targetY, visibleFrame.maxY - height - 8))

        setFrame(NSRect(x: targetX, y: targetY, width: width, height: height), display: true)

        if !isVisible {
            alphaValue = 0.0
            orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.16
                animator().alphaValue = 1.0
            }
        } else {
            orderFrontRegardless()
        }

        // If opened empty, start auto-hide countdown
        if BasketModel.shared.isEmpty && AppSettings.shared.autoHideEmpty {
            startAutoHideTimer()
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
        let delay = AppSettings.shared.autoHideDelay
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if BasketModel.shared.isEmpty {
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
