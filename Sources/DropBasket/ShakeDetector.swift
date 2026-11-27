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

    private var samples: [MovementSample] = []
    private var lastPoint: CGPoint?

    // Omnidirectional vector stroke accumulation
    private var currentStroke: CGPoint = .zero
    private var strokeReversalTimes: [TimeInterval] = []

    private var lastTriggerTime: TimeInterval = 0
    private let cooldown: TimeInterval = 0.55
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
        currentStroke = .zero
        strokeReversalTimes.removeAll()
        samples.removeAll()
    }

    private func processPoint(_ p: CGPoint, isDragging: Bool) {
        let now = Date().timeIntervalSinceReferenceDate
        if now - lastTriggerTime < cooldown {
            return
        }

        guard let prev = lastPoint else {
            lastPoint = p
            samples.append(MovementSample(point: p, timestamp: now))
            return
        }
        lastPoint = p

        let dx = p.x - prev.x
        let dy = p.y - prev.y
        let stepDist = hypot(dx, dy)

        // Ignore sub-pixel noise and hardware jitter (< 1.0 px)
        if stepDist < 1.0 {
            return
        }

        samples.append(MovementSample(point: p, timestamp: now))

        let sensitivity = AppSettings.shared.sensitivity
        let timeWindow = sensitivity.timeWindow
        let minStroke = sensitivity.minStrokeDistance
        let minReversals = sensitivity.minReversals
        let minTotalPath = sensitivity.minTotalPath

        // Purge samples and reversals older than the rolling time window
        let cutoff = now - timeWindow
        samples.removeAll { $0.timestamp < cutoff }
        strokeReversalTimes.removeAll { $0 < cutoff }

        // Vector turnaround analysis
        let currentStrokeLen = hypot(currentStroke.x, currentStroke.y)

        if currentStrokeLen < 0.5 {
            currentStroke = CGPoint(x: dx, y: dy)
        } else {
            // Dot product between current stroke vector and new movement vector
            let dot = (currentStroke.x * dx) + (currentStroke.y * dy)
            if dot < 0 {
                // Movement reversed direction relative to current stroke
                if currentStrokeLen >= minStroke {
                    strokeReversalTimes.append(now)
                }
                currentStroke = CGPoint(x: dx, y: dy)
            } else {
                // Movement continues in the general stroke direction
                currentStroke.x += dx
                currentStroke.y += dy
            }
        }

        guard samples.count >= 3 else { return }

        // Compute sliding window kinematics
        var totalPath: CGFloat = 0
        var minX = samples[0].point.x
        var maxX = samples[0].point.x
        var minY = samples[0].point.y
        var maxY = samples[0].point.y

        for i in 1..<samples.count {
            let p1 = samples[i - 1].point
            let p2 = samples[i].point
            totalPath += hypot(p2.x - p1.x, p2.y - p1.y)

            if p2.x < minX { minX = p2.x }
            if p2.x > maxX { maxX = p2.x }
            if p2.y < minY { minY = p2.y }
            if p2.y > maxY { maxY = p2.y }
        }

        let firstPt = samples.first!.point
        let lastPt = samples.last!.point
        let netDisplacement = hypot(lastPt.x - firstPt.x, lastPt.y - firstPt.y)
        let bboxDiag = hypot(maxX - minX, maxY - minY)

        let dispRatio = totalPath > 0 ? (netDisplacement / totalPath) : 1.0

        // Trigger condition 1: Oscillating reversals (wiggling or flicking back and forth)
        let conditionReversals = (strokeReversalTimes.count >= minReversals) &&
                                 (totalPath >= minTotalPath) &&
                                 (dispRatio <= 0.70)

        // Trigger condition 2: Kinematic wiggle / tight orbital wiggles / rapid loops
        let conditionKinematic = (totalPath >= minTotalPath * 1.25) &&
                                 (dispRatio <= 0.45) &&
                                 (strokeReversalTimes.count >= 1) &&
                                 (bboxDiag <= 80.0)

        if conditionReversals || conditionKinematic {
            lastTriggerTime = now
            resetStrokes()
            delegate?.didDetectShake(at: p, isDragging: isDragging)
        }
    }
}
