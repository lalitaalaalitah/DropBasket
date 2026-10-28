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

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: dropBasketEventTapCallback,
            userInfo: refcon
        )

        guard let tap = eventTap else {
            print("[\(Metadata.appName)] Failed to create CGEvent tap. Please check Accessibility permissions.")
            return false
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
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
            shakeDetector.handleMouseDown(at: loc)
        case .leftMouseDragged:
            shakeDetector.handleMouseDragged(at: loc)
        case .leftMouseUp:
            shakeDetector.handleMouseUp(at: loc)
        case .mouseMoved:
            shakeDetector.handleMouseMoved(at: loc)
        default:
            break
        }
    }

    // MARK: - ShakeDetectorDelegate

    public func didDetectShake(at point: CGPoint, isDragging: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if isDragging {
                self.onShakeDetected?(point, true)
            } else {
                if FinderHelper.shared.isFinderFrontmost {
                    let sel = FinderHelper.shared.getSelectedURLs()
                    if !sel.isEmpty {
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
