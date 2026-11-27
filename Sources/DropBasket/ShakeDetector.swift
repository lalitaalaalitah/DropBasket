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

public struct MovementSample: Sendable {
    public let point: CGPoint
    public let timestamp: TimeInterval

    public init(point: CGPoint, timestamp: TimeInterval) {
        self.point = point
        self.timestamp = timestamp
    }
}

public final class ShakeDetector: @unchecked Sendable {
    public weak var delegate: ShakeDetectorDelegate?

    public struct StrokeReversal: Sendable {
        public let time: TimeInterval
        public let vertex: CGPoint
        public let strokeLength: CGFloat

        public init(time: TimeInterval, vertex: CGPoint, strokeLength: CGFloat) {
            self.time = time
            self.vertex = vertex
            self.strokeLength = strokeLength
        }
    }

    private var reversals: [StrokeReversal] = []
    private var lastPoint: CGPoint?
    private var currentStroke: CGPoint = .zero

    private var lastTriggerTime: TimeInterval = 0
    private let cooldown: TimeInterval = 0.40
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
        // DropBasket strictly requires holding mouse down (dragging).
        // Free cursor movement never triggers the basket.
    }

    public func recordTrigger() {
        lastTriggerTime = Date().timeIntervalSinceReferenceDate
        resetStrokes()
    }

    public func resetStrokes() {
        lastPoint = nil
        currentStroke = .zero
        reversals.removeAll()
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
        let stepDist = hypot(dx, dy)

        // Ignore micro-sensor noise (< 1.0 px)
        if stepDist < 1.0 {
            return
        }

        let sensitivity = AppSettings.shared.sensitivity
        let timeWindow = sensitivity.timeWindow
        let minStroke = sensitivity.minStrokeDistance
        let minReversals = sensitivity.minReversals
        let minTotalPath = sensitivity.minTotalPath

        // Purge reversals older than the rolling time window
        let cutoff = now - timeWindow
        reversals.removeAll { $0.time < cutoff }

        // Vector turnaround analysis
        let currentStrokeLen = hypot(currentStroke.x, currentStroke.y)

        if currentStrokeLen < 0.5 {
            currentStroke = CGPoint(x: dx, y: dy)
        } else {
            // Normalized cosine of angle between accumulated stroke and new step
            let dot = (currentStroke.x * dx) + (currentStroke.y * dy)
            let cosAngle = dot / (currentStrokeLen * stepDist)

            // A reversal occurs when the direction changes sharply (angle > 115°, cos < -0.42).
            // Gentle curves, L-corners, and slight hand wobbles (cos > -0.42) do NOT count as reversals.
            if cosAngle < -0.42 {
                if currentStrokeLen >= minStroke {
                    reversals.append(StrokeReversal(time: now, vertex: prev, strokeLength: currentStrokeLen))
                }
                currentStroke = CGPoint(x: dx, y: dy)
            } else {
                currentStroke.x += dx
                currentStroke.y += dy
            }
        }

        // Trigger evaluation:
        // When enough qualifying deliberate reversals occur within the time window:
        if reversals.count >= minReversals {
            // Total distance across qualifying reversal strokes + current stroke
            let reversalPath = reversals.reduce(0.0) { $0 + $1.strokeLength }
            let totalShakePath = reversalPath + hypot(currentStroke.x, currentStroke.y)

            // Ensure the shake is localized around the cursor
            var minX = p.x, maxX = p.x, minY = p.y, maxY = p.y
            for rev in reversals {
                minX = min(minX, rev.vertex.x)
                maxX = max(maxX, rev.vertex.x)
                minY = min(minY, rev.vertex.y)
                maxY = max(maxY, rev.vertex.y)
            }
            let bboxDiag = hypot(maxX - minX, maxY - minY)

            if totalShakePath >= minTotalPath && bboxDiag <= 140.0 {
                lastTriggerTime = now
                resetStrokes()
                delegate?.didDetectShake(at: p, isDragging: isDragging)
                return
            }
        }
    }
}
