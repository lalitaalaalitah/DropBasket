//
//  QuickLookController.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import Quartz
import QuickLookUI

public final class QuickLookController: NSObject, @unchecked Sendable, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public static let shared = QuickLookController()

    private let lock = NSLock()
    private var _previewURLs: [URL] = []
    public var previewURLs: [URL] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _previewURLs
        }
        set {
            lock.lock()
            _previewURLs = newValue
            lock.unlock()
        }
    }
    public var currentIndex: Int = 0

    private override init() {
        super.init()
    }

    @MainActor
    public func togglePreview(for urls: [URL], initialIndex: Int = 0) {
        guard !urls.isEmpty else { return }
        self.previewURLs = urls
        self.currentIndex = min(max(0, initialIndex), urls.count - 1)

        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.dataSource = self
            panel.delegate = self
            panel.currentPreviewItemIndex = currentIndex
            panel.makeKeyAndOrderFront(nil)
        }
    }

    @MainActor
    public func previewSingle(url: URL) {
        togglePreview(for: [url], initialIndex: 0)
    }

    // MARK: - QLPreviewPanelDataSource

    nonisolated public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return previewURLs.count
    }

    nonisolated public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        let urls = previewURLs
        guard index >= 0 && index < urls.count else { return nil }
        return urls[index] as NSURL
    }
}
