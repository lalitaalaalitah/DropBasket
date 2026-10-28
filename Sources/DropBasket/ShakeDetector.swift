//
//  ShakeDetector.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Foundation
import CoreGraphics

public protocol ShakeDetectorDelegate: AnyObject, Sendable {
    func didDetectShake(at point: CGPoint, isDragging: Bool)
    func didEndDrag(at point: CGPoint)
}

public final class ShakeDetector: @unchecked Sendable {
    public weak var delegate: ShakeDetectorDelegate?

    private var lastPoint: CGPoint?
    private var dirX: Int = 0
    private var strokeDistX: CGFloat = 0
    private var reversalTimesX: [TimeInterval] = []

    private var dirY: Int = 0
    private var strokeDistY: CGFloat = 0
    private var reversalTimesY: [TimeInterval] = []

    private var lastTriggerTime: TimeInterval = 0
    private let cooldown: TimeInterval = 1.2
    public private(set) var isDragging: Bool = false

    public init() {}

    public func handleMouseDown(at point: CGPoint) {
        lastPoint = point
        isDragging = false
        resetStrokes()
    }

    public func handleMouseUp(at point: CGPoint) {
        let wasDragging = isDragging
        isDragging = false
        resetStrokes()
        if wasDragging {
            delegate?.didEndDrag(at: point)
        }
    }

    public func handleMouseDragged(at point: CGPoint) {
        isDragging = true
        processPoint(point, isDragging: true)
    }

    public func handleMouseMoved(at point: CGPoint) {
        guard AppSettings.shared.triggerOnFinderSelection else { return }
        processPoint(point, isDragging: false)
    }

    private func resetStrokes() {
        lastPoint = nil
        dirX = 0
        strokeDistX = 0
        reversalTimesX.removeAll()
        dirY = 0
        strokeDistY = 0
        reversalTimesY.removeAll()
    }

    private func processPoint(_ p: CGPoint, isDragging: Bool) {
        let now = Date().timeIntervalSinceReferenceDate
        if now - lastTriggerTime < cooldown {
            return
        }

        guard let prev = lastPoint else {
            lastPoint = p
            return
        }
        lastPoint = p

        let dx = p.x - prev.x
        let dy = p.y - prev.y

        let sensitivity = AppSettings.shared.sensitivity
        let minStroke = sensitivity.minStrokeDistance
        let minReversals = sensitivity.minReversals
        let timeWindow = sensitivity.timeWindow

        // Horizontal axis analysis
        if abs(dx) > 1.5 {
            let sign = dx > 0 ? 1 : -1
            if dirX != 0 && sign != dirX {
                if strokeDistX >= minStroke {
                    reversalTimesX.append(now)
                }
                strokeDistX = 0
            }
            dirX = sign
            strokeDistX += abs(dx)
        }

        // Vertical axis analysis
        if abs(dy) > 1.5 {
            let sign = dy > 0 ? 1 : -1
            if dirY != 0 && sign != dirY {
                if strokeDistY >= minStroke {
                    reversalTimesY.append(now)
                }
                strokeDistY = 0
            }
            dirY = sign
            strokeDistY += abs(dy)
        }

        // Filter reversals outside time window
        reversalTimesX.removeAll { now - $0 > timeWindow }
        reversalTimesY.removeAll { now - $0 > timeWindow }

        if reversalTimesX.count >= minReversals || reversalTimesY.count >= minReversals {
            lastTriggerTime = now
            resetStrokes()
            delegate?.didDetectShake(at: p, isDragging: isDragging)
        }
    }
}
