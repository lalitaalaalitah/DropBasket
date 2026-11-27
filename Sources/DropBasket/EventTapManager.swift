//
//  EventTapManager.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import CoreGraphics

// Top-level nonisolated C-callback to eliminate any Swift actor check and SIGTRAP crashes
private func dropBasketEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
    }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    manager.handleCGEvent(type: type, event: event)
    return Unmanaged.passUnretained(event)
}

public final class EventTapManager: @unchecked Sendable, ShakeDetectorDelegate {
    public static let shared = EventTapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    public let shakeDetector = ShakeDetector()

    private let pasteboardLock = NSLock()
    private var _mouseDownDragChangeCount: Int = -1
    public var mouseDownDragChangeCount: Int {
        get {
            pasteboardLock.lock()
            defer { pasteboardLock.unlock() }
            return _mouseDownDragChangeCount
        }
        set {
            pasteboardLock.lock()
            defer { pasteboardLock.unlock() }
            _mouseDownDragChangeCount = newValue
        }
    }

    public var onShakeDetected: (@MainActor @Sendable (CGPoint, Bool) -> Void)?
    public var onDragEnded: (@MainActor @Sendable (CGPoint) -> Void)?

    private init() {
        shakeDetector.delegate = self
    }

    public func start() -> Bool {
        stop()

        var mask = (1 << CGEventType.leftMouseDown.rawValue) |
                   (1 << CGEventType.leftMouseDragged.rawValue) |
                   (1 << CGEventType.leftMouseUp.rawValue)

        if AppSettings.shared.triggerOnFinderSelection {
            mask |= (1 << CGEventType.mouseMoved.rawValue)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // Prefer .cgSessionEventTap for user login session accessibility tools
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: dropBasketEventTapCallback,
            userInfo: refcon
        )

        // Fallback to .cghidEventTap if session tap is unavailable
        if eventTap == nil {
            eventTap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: CGEventMask(mask),
                callback: dropBasketEventTapCallback,
                userInfo: refcon
            )
        }

        guard let tap = eventTap else {
            print("[\(Metadata.appName)] Failed to create CGEvent tap. Please check Accessibility permissions.")
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        mouseDownDragChangeCount = NSPasteboard(name: .drag).changeCount
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[\(Metadata.appName)] Event tap successfully enabled.")
        return true
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
        }
    }

    public func handleCGEvent(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = self.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return
        }

        let loc = event.location
        switch type {
        case .leftMouseDown:
            mouseDownDragChangeCount = NSPasteboard(name: .drag).changeCount
            shakeDetector.handleMouseDown(at: loc)
        case .leftMouseDragged:
            shakeDetector.handleMouseDragged(at: loc)
        case .leftMouseUp:
            shakeDetector.handleMouseUp(at: loc)
            mouseDownDragChangeCount = NSPasteboard(name: .drag).changeCount
        case .mouseMoved:
            shakeDetector.handleMouseMoved(at: loc)
        default:
            break
        }
    }

    // MARK: - Drag State Validation (Rejects Text Selection)

    public func isSystemFileDragInProgress() -> Bool {
        let dragPb = NSPasteboard(name: .drag)
        let currentChangeCount = dragPb.changeCount
        let initialCount = self.mouseDownDragChangeCount

        // 1. A new drag session MUST have been initiated during this mouse-down gesture.
        // Selecting text or moving the mouse with button down does NOT start a drag session,
        // so NSPasteboard.Name.drag.changeCount remains identical to initialCount.
        guard initialCount >= 0, currentChangeCount != initialCount else {
            return false
        }

        // 2. The drag session MUST contain file URLs or file objects, NOT text or arbitrary web URLs.
        return hasFileContent(in: dragPb)
    }

    public func hasFileContent(in pasteboard: NSPasteboard) -> Bool {
        guard let types = pasteboard.types, !types.isEmpty else { return false }

        // Fast in-memory check for file-related pasteboard types (zero IPC latency)
        let fileTypes: Set<NSPasteboard.PasteboardType> = [
            .fileURL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.finder.node"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"),
            NSPasteboard.PasteboardType("NSFilesPromisePboardType")
        ]

        if types.contains(where: { fileTypes.contains($0) }) {
            return true
        }

        // Method 2: direct file URLs fallback
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            return true
        }

        return false
    }

    // MARK: - ShakeDetectorDelegate

    public func didDetectShake(at point: CGPoint, isDragging: Bool) {
        if isDragging {
            // Must be an active file drag session! Rejects text selections and text drags.
            guard self.isSystemFileDragInProgress() else {
                return
            }
            self.shakeDetector.recordTrigger()
            DispatchQueue.main.async { [weak self] in
                self?.onShakeDetected?(point, true)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if FinderHelper.shared.isFinderFrontmost {
                    let sel = FinderHelper.shared.getSelectedURLs()
                    if !sel.isEmpty {
                        self.shakeDetector.recordTrigger()
                        self.onShakeDetected?(point, false)
                    }
                }
            }
        }
    }

    public func didEndDrag(at point: CGPoint) {
        DispatchQueue.main.async { [weak self] in
            self?.onDragEnded?(point)
        }
    }
}
