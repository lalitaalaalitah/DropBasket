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

@MainActor
public final class EventTapManager: ShakeDetectorDelegate {
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

        let mask = (1 << CGEventType.leftMouseDown.rawValue) |
                   (1 << CGEventType.leftMouseDragged.rawValue) |
                   (1 << CGEventType.leftMouseUp.rawValue) |
                   (1 << CGEventType.mouseMoved.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
                manager.handleCGEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
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

    nonisolated private func handleCGEvent(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            Task { @MainActor in
                if let tap = self.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
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

    nonisolated public func didDetectShake(at point: CGPoint, isDragging: Bool) {
        Task { @MainActor in
            self.handleShakeOnMain(at: point, isDragging: isDragging)
        }
    }

    nonisolated public func didEndDrag(at point: CGPoint) {
        Task { @MainActor in
            self.onDragEnded?(point)
        }
    }

    private func handleShakeOnMain(at point: CGPoint, isDragging: Bool) {
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
