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

    public init(title: String) {
        super.init(frame: .zero)
        self.title = title
        self.bezelStyle = .inline
        self.isBordered = false
        self.wantsLayer = true
        self.layer?.cornerRadius = 6
        self.layer?.backgroundColor = Catppuccin.blue.cgColor

        let attrTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: Catppuccin.crust,
                .font: NSFont.systemFont(ofSize: 11, weight: .bold)
            ]
        )
        self.attributedTitle = attrTitle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        if dist > 4.0 {
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
            let frame = NSRect(x: CGFloat(index * 6), y: 0, width: 38, height: 38)
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

// MARK: - Draggable Item Row View with Rich Metadata (Catppuccin Themed)

@MainActor
public class BasketItemRowView: NSView, NSDraggingSource {
    public let item: BasketItem
    public var onRemove: (() -> Void)?
    public var onReveal: (() -> Void)?
    public var onPreview: (() -> Void)?
    public var onToggleMove: (() -> Void)?
    public var onDragSessionEnded: ((NSDragOperation) -> Void)?

    public override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 74)
    }

    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let extBadge = NSTextField(labelWithString: "")
    private let kindAndSizeLabel = NSTextField(labelWithString: "")
    private let dirAndDateLabel = NSTextField(labelWithString: "")
    private let modeBadgeButton = NSButton()

    private let previewBtn = NSButton()
    private let revealBtn = NSButton()
    private let removeBtn = NSButton()
    private var trackingAreaRef: NSTrackingArea?
    private var mouseDownPoint: NSPoint?

    public init(item: BasketItem) {
        self.item = item
        super.init(frame: NSRect(x: 0, y: 0, width: 376, height: 74))
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.backgroundColor = Catppuccin.surface0.cgColor
        layer?.borderWidth = 1.0
        layer?.borderColor = Catppuccin.surface1.cgColor
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
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        nameLabel.textColor = Catppuccin.text
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        // Extension pill badge
        extBadge.stringValue = " \(item.extensionString) "
        extBadge.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .bold)
        extBadge.textColor = Catppuccin.sapphire
        extBadge.wantsLayer = true
        extBadge.layer?.cornerRadius = 4
        extBadge.layer?.backgroundColor = Catppuccin.mantle.cgColor
        extBadge.layer?.masksToBounds = true
        extBadge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(extBadge)

        // Kind and Size (e.g. "PNG Image • 2.4 MB")
        kindAndSizeLabel.stringValue = "\(item.kind) • \(item.sizeString)"
        kindAndSizeLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        kindAndSizeLabel.textColor = Catppuccin.subtext0
        kindAndSizeLabel.lineBreakMode = .byTruncatingTail
        kindAndSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(kindAndSizeLabel)

        // Directory and Date (e.g. "📁 in Downloads • Today, 04:30")
        dirAndDateLabel.stringValue = "📁 in \(item.directoryName) • \(item.modificationDateString)"
        dirAndDateLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        dirAndDateLabel.textColor = Catppuccin.overlay1
        dirAndDateLabel.lineBreakMode = .byTruncatingTail
        dirAndDateLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dirAndDateLabel)

        // Mode badge button ([COPY] or [MOVE])
        updateModeBadge()
        modeBadgeButton.isBordered = false
        modeBadgeButton.wantsLayer = true
        modeBadgeButton.layer?.cornerRadius = 4
        modeBadgeButton.target = self
        modeBadgeButton.action = #selector(modeBadgeClicked)
        modeBadgeButton.toolTip = "Click to toggle between Copy and Move"
        modeBadgeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(modeBadgeButton)

        // Action buttons
        setupActionButton(previewBtn, title: "👁", tooltip: "Quick Look (Space)", color: Catppuccin.lavender, action: #selector(previewClicked))
        setupActionButton(revealBtn, title: "↗", tooltip: "Reveal in Finder", color: Catppuccin.sky, action: #selector(revealClicked))
        setupActionButton(removeBtn, title: "✕", tooltip: "Remove from Basket", color: Catppuccin.red, action: #selector(removeClicked))

        let btnStack = NSStackView(views: [previewBtn, revealBtn, removeBtn])
        btnStack.orientation = .horizontal
        btnStack.spacing = 4
        btnStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(btnStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            extBadge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 6),
            extBadge.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            extBadge.trailingAnchor.constraint(lessThanOrEqualTo: btnStack.leadingAnchor, constant: -6),

            kindAndSizeLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            kindAndSizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            kindAndSizeLabel.trailingAnchor.constraint(equalTo: btnStack.leadingAnchor, constant: -6),

            dirAndDateLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            dirAndDateLabel.topAnchor.constraint(equalTo: kindAndSizeLabel.bottomAnchor, constant: 2),
            dirAndDateLabel.trailingAnchor.constraint(equalTo: modeBadgeButton.leadingAnchor, constant: -6),

            modeBadgeButton.trailingAnchor.constraint(equalTo: btnStack.leadingAnchor, constant: -8),
            modeBadgeButton.centerYAnchor.constraint(equalTo: dirAndDateLabel.centerYAnchor),
            modeBadgeButton.heightAnchor.constraint(equalToConstant: 18),

            btnStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            btnStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            btnStack.widthAnchor.constraint(equalToConstant: 80),
            btnStack.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    public func updateModeBadge() {
        let isMove = item.isMoveOperation
        let text = isMove ? " ⌘ MOVE " : " COPY "
        let color = isMove ? Catppuccin.peach : Catppuccin.teal
        let bg = isMove ? Catppuccin.peach.withAlphaComponent(0.2) : Catppuccin.teal.withAlphaComponent(0.2)

        let attr = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: color,
                .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold)
            ]
        )
        modeBadgeButton.attributedTitle = attr
        modeBadgeButton.layer?.backgroundColor = bg.cgColor
    }

    @objc private func modeBadgeClicked() {
        onToggleMove?()
    }

    private func setupActionButton(_ btn: NSButton, title: String, tooltip: String, color: NSColor, action: Selector) {
        btn.bezelStyle = .regularSquare
        btn.isBordered = false
        btn.target = self
        btn.action = action
        btn.toolTip = tooltip
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 5
        btn.layer?.backgroundColor = Catppuccin.surface1.cgColor

        let attr = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 12, weight: .medium)
            ]
        )
        btn.attributedTitle = attr
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 24).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 24).isActive = true
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
        layer?.backgroundColor = Catppuccin.surface1.cgColor
        layer?.borderColor = Catppuccin.surface2.cgColor
    }

    public override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = Catppuccin.surface0.cgColor
        layer?.borderColor = Catppuccin.surface1.cgColor
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
            let dragRect = NSRect(x: 0, y: 0, width: 40, height: 40)
            dragItem.setDraggingFrame(dragRect, contents: item.icon)
            beginDraggingSession(with: [dragItem], event: event, source: self)
        }
    }

    nonisolated public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        let isCmd = NSEvent.modifierFlags.contains(.command)
        if isCmd || item.isMoveOperation {
            return [.move, .copy, .generic]
        } else {
            return [.copy, .generic]
        }
    }

    nonisolated public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        Task { @MainActor in
            self.onDragSessionEnded?(operation)
        }
    }
}
