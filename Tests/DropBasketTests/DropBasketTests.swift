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
import Cocoa
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

    @Test func testCatppuccinMochaPalette() {
        #expect(Catppuccin.base.numberOfComponents >= 3)
        #expect(Catppuccin.text.numberOfComponents >= 3)
        #expect(Catppuccin.mauve.numberOfComponents >= 3)
        #expect(Catppuccin.peach.numberOfComponents >= 3)
        #expect(Catppuccin.teal.numberOfComponents >= 3)
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

    @Test func testQuickShakeTriggersEffortlessly() {
        let detector = ShakeDetector()
        let delegate = MockShakeDelegate()
        detector.delegate = delegate

        AppSettings.shared.sensitivity = .medium

        detector.handleMouseDown(at: CGPoint(x: 100, y: 100))

        // Quick back-and-forth flick: 100 -> 120 -> 95 -> 120
        let targets: [CGFloat] = [120, 95, 120]
        var currentX: CGFloat = 100
        for target in targets {
            let step: CGFloat = target > currentX ? 4 : -4
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
    @Test @MainActor func testAddWithMetadataAndMoveMode() {
        let model = BasketModel.shared
        model.clear()
        #expect(model.isEmpty)

        let tempDir = FileManager.default.temporaryDirectory
        let fileA = tempDir.appendingPathComponent("document.txt")
        let fileB = tempDir.appendingPathComponent("image.png")

        try? "Document Text".write(to: fileA, atomically: true, encoding: .utf8)
        try? "PNG Fake Bytes".write(to: fileB, atomically: true, encoding: .utf8)

        // Drop fileA with default Copy, fileB with Cmd+Move
        let added = model.add(urls: [fileA], isMove: false)
        #expect(added == 1)
        #expect(model.items.first?.isMoveOperation == false)
        #expect(model.items.first?.extensionString == "TXT")

        let addedB = model.add(urls: [fileB], isMove: true)
        #expect(addedB == 1)
        #expect(model.items.last?.isMoveOperation == true)
        #expect(model.items.last?.extensionString == "PNG")
        #expect(!model.items.last!.modificationDateString.isEmpty)

        // Toggle Move
        if let first = model.items.first {
            model.toggleMove(item: first)
            #expect(model.items.first?.isMoveOperation == true)
        }

        // Clean
        model.clear()
        #expect(model.isEmpty)

        try? FileManager.default.removeItem(at: fileA)
        try? FileManager.default.removeItem(at: fileB)
    }
}
