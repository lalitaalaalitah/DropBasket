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
        #expect(CLI.__version__ == "1.0.0")
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

    @Test func testQuickHorizontalShakeTriggersEffortlessly() {
        let detector = ShakeDetector()
        let delegate = MockShakeDelegate()
        detector.delegate = delegate

        AppSettings.shared.sensitivity = .medium

        detector.handleMouseDown(at: CGPoint(x: 100, y: 100))

        // Quick back-and-forth flick: 100 -> 118 -> 96 -> 116
        let targets: [CGFloat] = [118, 96, 116]
        var currentX: CGFloat = 100
        for target in targets {
            let step: CGFloat = target > currentX ? 3.5 : -3.5
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

    @Test func testDiagonalShakeTriggersEffortlessly() {
        let detector = ShakeDetector()
        let delegate = MockShakeDelegate()
        detector.delegate = delegate

        AppSettings.shared.sensitivity = .medium

        detector.handleMouseDown(at: CGPoint(x: 100, y: 100))

        // Diagonal flick at 45°: (100,100) -> (114,114) -> (96,96) -> (112,112)
        let targets: [CGPoint] = [
            CGPoint(x: 114, y: 114),
            CGPoint(x: 96, y: 96),
            CGPoint(x: 112, y: 112)
        ]
        var current = CGPoint(x: 100, y: 100)
        for target in targets {
            let stepX: CGFloat = target.x > current.x ? 3 : -3
            let stepY: CGFloat = target.y > current.y ? 3 : -3
            while (stepX > 0 && current.x < target.x) || (stepX < 0 && current.x > target.x) {
                current.x += stepX
                current.y += stepY
                detector.handleMouseDragged(at: current)
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

    @Test func testSubpixelNoiseDoesNotBreakShake() {
        let detector = ShakeDetector()
        let delegate = MockShakeDelegate()
        detector.delegate = delegate

        AppSettings.shared.sensitivity = .medium
        detector.handleMouseDown(at: CGPoint(x: 200, y: 200))

        // Interleave strokes with realistic subpixel jitter (< 1.0 px)
        var x: CGFloat = 200
        for _ in 0..<5 {
            x += 3.5
            detector.handleMouseDragged(at: CGPoint(x: x, y: 200))
            // Jitter frame that should be filtered
            detector.handleMouseDragged(at: CGPoint(x: x + 0.3, y: 200.2))
        }
        for _ in 0..<6 {
            x -= 3.5
            detector.handleMouseDragged(at: CGPoint(x: x, y: 200))
            detector.handleMouseDragged(at: CGPoint(x: x - 0.2, y: 199.8))
        }
        for _ in 0..<5 {
            x += 3.5
            detector.handleMouseDragged(at: CGPoint(x: x, y: 200))
        }

        #expect(!delegate.detectedShakes.isEmpty)
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

@Suite struct BasketViewsTests {
    @Test @MainActor func testBasketItemRowViewFlippedAndMetadata() {
        let tempDir = FileManager.default.temporaryDirectory
        let sampleFile = tempDir.appendingPathComponent("Report.pdf")
        try? "PDF Sample Data".write(to: sampleFile, atomically: true, encoding: .utf8)

        let item = BasketItem(url: sampleFile, isMove: false)
        let rowView = BasketItemRowView(item: item)

        #expect(rowView.isFlipped == true)
        #expect(rowView.intrinsicContentSize.height == 74)

        // Verify layout can execute without crashing
        rowView.frame = NSRect(x: 0, y: 0, width: 376, height: 74)
        rowView.layoutSubtreeIfNeeded()

        #expect(rowView.subviews.count >= 6)

        try? FileManager.default.removeItem(at: sampleFile)
    }

    @Test @MainActor func testMenuBarIconAndBadge() {
        let menuBar = MenuBarController.shared
        menuBar.setup()
        menuBar.updateStatusItemIconAndTitle()

        let model = BasketModel.shared
        model.clear()
        menuBar.updateStatusItemIconAndTitle()

        let tempDir = FileManager.default.temporaryDirectory
        let sample = tempDir.appendingPathComponent("Test.txt")
        try? "Test".write(to: sample, atomically: true, encoding: .utf8)

        model.add(urls: [sample], isMove: false)
        menuBar.updateStatusItemIconAndTitle()
        #expect(model.count == 1)

        model.clear()
        menuBar.updateStatusItemIconAndTitle()
        #expect(model.count == 0)

        try? FileManager.default.removeItem(at: sample)
    }
}

@Suite struct ServiceManagerTests {
    @Test func testServiceManagerPlistGeneration() {
        let fakePath = "/Applications/DropBasket.app/Contents/MacOS/DropBasket"
        let plist = ServiceManager.generatePlistContent(binaryPath: fakePath)

        #expect(plist.contains("<string>com.lalitaalaalitah.DropBasket</string>"))
        #expect(plist.contains("<string>\(fakePath)</string>"))
        #expect(plist.contains("<key>RunAtLoad</key>"))
        #expect(plist.contains("<key>KeepAlive</key>"))
        #expect(ServiceManager.plistURL.lastPathComponent == "com.lalitaalaalitah.DropBasket.plist")
    }
}
