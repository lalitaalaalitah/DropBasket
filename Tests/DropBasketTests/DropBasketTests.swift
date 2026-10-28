//
//  DropBasketTests.swift
//  DropBasketTests
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Testing
import Foundation
import CoreGraphics
@testable import DropBasket

final class MockShakeDelegate: ShakeDetectorDelegate, @unchecked Sendable {
    var detectedShakes: [CGPoint] = []
    var detectedIsDragging: [Bool] = []
    var endedDrags: [CGPoint] = []

    func didDetectShake(at point: CGPoint, isDragging: Bool) {
        detectedShakes.append(point)
        detectedIsDragging.append(isDragging)
    }

    func didEndDrag(at point: CGPoint) {
        endedDrags.append(point)
    }
}

@Suite struct MetadataTests {
    @Test func testBrandingMetadata() {
        #expect(Metadata.author == "lalitaalaalitah")
        #expect(Metadata.website == "https://www.lalitaalaalitah.com")
        #expect(Metadata.github == "https://github.com/lalitaalaalitah")
        #expect(Metadata.appVersion == "1.0.0")
        #expect(Metadata.bundleIdentifier == "com.lalitaalaalitah.DropBasket")
    }
}

@Suite struct ShakeDetectorTests {
    @Test func testStraightDragDoesNotTrigger() {
        let detector = ShakeDetector()
        let delegate = MockShakeDelegate()
        detector.delegate = delegate

        detector.handleMouseDown(at: CGPoint(x: 100, y: 100))
        for x in stride(from: 100, through: 600, by: 10) {
            detector.handleMouseDragged(at: CGPoint(x: CGFloat(x), y: 100))
        }
        detector.handleMouseUp(at: CGPoint(x: 600, y: 100))

        #expect(delegate.detectedShakes.isEmpty)
        #expect(delegate.endedDrags.count == 1)
    }

    @Test func testShakeBackAndForthTriggers() {
        let detector = ShakeDetector()
        let delegate = MockShakeDelegate()
        detector.delegate = delegate

        AppSettings.shared.sensitivity = .medium

        detector.handleMouseDown(at: CGPoint(x: 100, y: 100))

        // Shake: 100 -> 160 -> 80 -> 170 -> 70
        let targets: [CGFloat] = [160, 80, 170, 70, 160]
        var currentX: CGFloat = 100
        for target in targets {
            let step: CGFloat = target > currentX ? 6 : -6
            while (step > 0 && currentX < target) || (step < 0 && currentX > target) {
                currentX += step
                detector.handleMouseDragged(at: CGPoint(x: currentX, y: 100))
                if !delegate.detectedShakes.isEmpty {
                    break
                }
            }
            if !delegate.detectedShakes.isEmpty {
                break
            }
        }

        #expect(!delegate.detectedShakes.isEmpty)
        #expect(delegate.detectedIsDragging.first == true)
    }
}

@Suite struct BasketModelTests {
    @Test @MainActor func testAddAndDeduplicateItems() {
        let model = BasketModel.shared
        model.clear()
        #expect(model.isEmpty)

        let tempDir = FileManager.default.temporaryDirectory
        let fileA = tempDir.appendingPathComponent("testA.txt")
        let fileB = tempDir.appendingPathComponent("testB.txt")

        try? "File A content".write(to: fileA, atomically: true, encoding: .utf8)
        try? "File B content".write(to: fileB, atomically: true, encoding: .utf8)

        let added = model.add(urls: [fileA, fileB])
        #expect(added == 2)
        #expect(model.count == 2)

        // Duplicate add
        let duplicateAdded = model.add(urls: [fileA])
        #expect(duplicateAdded == 0)
        #expect(model.count == 2)

        // Remove item
        if let first = model.items.first {
            model.remove(item: first)
            #expect(model.count == 1)
        }

        // Clear
        model.clear()
        #expect(model.isEmpty)

        try? FileManager.default.removeItem(at: fileA)
        try? FileManager.default.removeItem(at: fileB)
    }
}
