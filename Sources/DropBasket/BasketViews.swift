//
//  BasketViews.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import Quartz

// MARK: - Draggable Button (for "Drag All")

@MainActor
public class DraggableAllButton: NSButton, NSDraggingSource {
    public var itemsProvider: (() -> [BasketItem])?
    public var onDragSessionEnded: ((NSDragOperation) -> Void)?

    private var mouseDownLocation: NSPoint?

    public override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        super.mouseDown(with: event)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard let down = mouseDownLocation else {
            super.mouseDragged(with: event)
            return
        }
        let current = event.locationInWindow
        let dist = hypot(current.x - down.x, current.y - down.y)
        if dist > 5.0 {
            startDragAllSession(with: event)
        } else {
            super.mouseDragged(with: event)
        }
    }

    private func startDragAllSession(with event: NSEvent) {
        guard let items = itemsProvider?(), !items.isEmpty else { return }

        var draggingItems: [NSDraggingItem] = []
        for (index, item) in items.enumerated() {
            let dragItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
            let frame = NSRect(x: CGFloat(index * 6), y: 0, width: 32, height: 32)
            dragItem.setDraggingFrame(frame, contents: item.icon)
            draggingItems.append(dragItem)
        }

        beginDraggingSession(with: draggingItems, event: event, source: self)
    }

    // MARK: - NSDraggingSource

    nonisolated public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return [.copy, .move, .generic]
    }

    nonisolated public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        Task { @MainActor in
            self.onDragSessionEnded?(operation)
        }
    }
}

// MARK: - Draggable Item Row View

@MainActor
public class BasketItemRowView: NSView, NSDraggingSource {
    public let item: BasketItem
    public var onRemove: (() -> Void)?
    public var onReveal: (() -> Void)?
    public var onPreview: (() -> Void)?
    public var onDragSessionEnded: ((NSDragOperation) -> Void)?

    private var isHovered = false
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let previewBtn = NSButton()
    private let revealBtn = NSButton()
    private let removeBtn = NSButton()
    private var trackingAreaRef: NSTrackingArea?
    private var mouseDownPoint: NSPoint?

    public init(item: BasketItem) {
        self.item = item
        super.init(frame: NSRect(x: 0, y: 0, width: 340, height: 48))
        wantsLayer = true
        layer?.cornerRadius = 8
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Icon
        iconView.image = item.icon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        // Name
        nameLabel.stringValue = item.name
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Detail
        let folderName = item.url.deletingLastPathComponent().lastPathComponent
        detailLabel.stringValue = "\(item.sizeString) • \(folderName)"
        detailLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

        // Buttons
        setupButton(previewBtn, title: "👁", tooltip: "Quick Look (Space)", action: #selector(previewClicked))
        setupButton(revealBtn, title: "↗", tooltip: "Reveal in Finder", action: #selector(revealClicked))
        setupButton(removeBtn, title: "✕", tooltip: "Remove from Basket", action: #selector(removeClicked))

        let btnStack = NSStackView(views: [previewBtn, revealBtn, removeBtn])
        btnStack.orientation = .horizontal
        btnStack.spacing = 4
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(btnStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: btnStack.leadingAnchor, constant: -6),

            detailLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            detailLabel.trailingAnchor.constraint(equalTo: btnStack.leadingAnchor, constant: -6),

            btnStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            btnStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func setupButton(_ btn: NSButton, title: String, tooltip: String, action: Selector) {
        btn.title = title
        btn.toolTip = tooltip
        btn.isBordered = false
        btn.target = self
        btn.action = action
        btn.font = NSFont.systemFont(ofSize: 12)
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 4
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 22).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let old = trackingAreaRef {
            removeTrackingArea(old)
        }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingAreaRef = area
    }

    public override func mouseEntered(with event: NSEvent) {
        isHovered = true
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.08).cgColor
    }

    public override func mouseExited(with event: NSEvent) {
        isHovered = false
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @objc private func previewClicked() {
        onPreview?()
    }

    @objc private func revealClicked() {
        onReveal?()
    }

    @objc private func removeClicked() {
        onRemove?()
    }

    // Dragging source support
    public override func mouseDown(with event: NSEvent) {
        mouseDownPoint = event.locationInWindow
    }

    public override func mouseDragged(with event: NSEvent) {
        guard let start = mouseDownPoint else { return }
        let current = event.locationInWindow
        let dist = hypot(current.x - start.x, current.y - start.y)
        if dist > 4.0 {
            let dragItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
            let dragRect = NSRect(x: 0, y: 0, width: 32, height: 32)
            dragItem.setDraggingFrame(dragRect, contents: item.icon)
            beginDraggingSession(with: [dragItem], event: event, source: self)
        }
    }

    nonisolated public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return [.copy, .move, .generic]
    }

    nonisolated public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        Task { @MainActor in
            self.onDragSessionEnded?(operation)
        }
    }
}
