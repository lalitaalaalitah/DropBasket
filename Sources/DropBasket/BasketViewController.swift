//
//  BasketViewController.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa

@MainActor
public class BasketRootDropView: NSView {
    public var onDraggingEntered: ((NSDraggingInfo) -> NSDragOperation)?
    public var onDraggingUpdated: ((NSDraggingInfo) -> NSDragOperation)?
    public var onDraggingExited: ((NSDraggingInfo?) -> Void)?
    public var onPerformDrag: (([URL], Bool) -> Bool)?

    private var isHighlighted: Bool = false
    private var isCommandHeld: Bool = false

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isCommandHeld = NSEvent.modifierFlags.contains(.command)
        let op = onDraggingEntered?(sender) ?? (isCommandHeld ? .move : [.copy, .generic])
        setHighlight(true, isCmd: isCommandHeld)
        return op
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        isCommandHeld = NSEvent.modifierFlags.contains(.command)
        let op = onDraggingUpdated?(sender) ?? (isCommandHeld ? .move : [.copy, .generic])
        setHighlight(true, isCmd: isCommandHeld)
        return op
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) {
        setHighlight(false, isCmd: false)
        onDraggingExited?(sender)
    }

    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        setHighlight(false, isCmd: false)
        let pb = sender.draggingPasteboard
        let isCmd = NSEvent.modifierFlags.contains(.command)
        let urls = extractURLs(from: pb)

        if !urls.isEmpty {
            return onPerformDrag?(urls, isCmd) ?? false
        }
        return false
    }

    private func extractURLs(from pasteboard: NSPasteboard) -> [URL] {
        var results: [URL] = []

        // Method 1: readObjects with NSURL
        if let nsUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL] {
            for u in nsUrls {
                if let fileUrl = u.filePathURL ?? (u as URL).standardizedFileURL as URL? {
                    results.append(fileUrl)
                }
            }
        }

        // Method 2: pasteboardItems with .fileURL
        if results.isEmpty, let items = pasteboard.pasteboardItems {
            for item in items {
                if let str = item.string(forType: .fileURL), let u = URL(string: str) {
                    results.append(u.standardizedFileURL)
                }
            }
        }

        // Method 3: legacy NSFilenamesPboardType
        if results.isEmpty, let paths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            for p in paths {
                results.append(URL(fileURLWithPath: p).standardizedFileURL)
            }
        }

        // Method 4: string forType .fileURL
        if results.isEmpty, let str = pasteboard.string(forType: .fileURL), let u = URL(string: str) {
            results.append(u.standardizedFileURL)
        }

        // Deduplicate
        var unique: [URL] = []
        for u in results {
            if !unique.contains(where: { $0.path == u.path }) {
                unique.append(u)
            }
        }
        return unique
    }

    private func setHighlight(_ highlighted: Bool, isCmd: Bool) {
        isHighlighted = highlighted
        isCommandHeld = isCmd
        needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 16, yRadius: 16)
            path.lineWidth = 3.5
            let strokeColor = isCommandHeld ? Catppuccin.peach : Catppuccin.mauve
            strokeColor.setStroke()
            path.stroke()
        }
    }
}

@MainActor
public class BasketViewController: NSViewController, BasketModelDelegate {
    private let model = BasketModel.shared
    private let containerView = BasketRootDropView()
    private let visualEffectView = NSVisualEffectView()
    private let catppuccinBackground = NSView()

    // Header views
    private let headerView = NSView()
    private let titleLabel = NSTextField(labelWithString: "🧺 DropBasket")
    private let spacePill = NSTextField(labelWithString: "")
    private let countBadge = NSTextField(labelWithString: "")
    private let dragAllButton = DraggableAllButton(title: "📦 Drag All")
    private let copyButton = NSButton()
    private let closeButton = NSButton()

    // Empty state views (Dedicated Drop Zone)
    private let emptyView = NSView()
    private let emptyIconLabel = NSTextField(labelWithString: "🧺")
    private let emptyTitleLabel = NSTextField(labelWithString: "Release Mouse to Drop Files")
    private let emptySubtitleLabel = NSTextField(labelWithString: "Default: Copy • Hold ⌘ to Move\nShake cursor anywhere while dragging to summon")
    private let emptyModeHint = NSTextField(labelWithString: "")
    private let importFinderButton = NSButton()

    // Populated state views
    private let populatedView = NSView()
    private let scrollView = NSScrollView()
    private let itemsStackView = NSStackView()

    // Footer views
    private let footerView = NSView()
    private let modeButton = NSButton()
    private let moveToButton = NSButton()
    private let clearButton = NSButton()
    private let hintLabel = NSTextField(labelWithString: "")

    public override func loadView() {
        containerView.frame = NSRect(x: 0, y: 0, width: 400, height: 460)
        self.view = containerView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        model.delegate = self
        setupVisualEffect()
        setupHeader()
        setupEmptyState()
        setupPopulatedState()
        setupFooter()
        setupDropCallbacks()
        refreshUI()
    }

    private func setupVisualEffect() {
        visualEffectView.frame = containerView.bounds
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        containerView.addSubview(visualEffectView)

        catppuccinBackground.frame = containerView.bounds
        catppuccinBackground.autoresizingMask = [.width, .height]
        catppuccinBackground.wantsLayer = true
        catppuccinBackground.layer?.cornerRadius = 16
        catppuccinBackground.layer?.masksToBounds = true
        catppuccinBackground.layer?.backgroundColor = Catppuccin.base.withAlphaComponent(0.94).cgColor
        catppuccinBackground.layer?.borderWidth = 1.5
        catppuccinBackground.layer?.borderColor = Catppuccin.surface1.cgColor
        containerView.addSubview(catppuccinBackground)
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        catppuccinBackground.addSubview(headerView)

        titleLabel.stringValue = "🧺 DropBasket"
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .heavy)
        titleLabel.textColor = Catppuccin.mauve
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        spacePill.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        spacePill.textColor = Catppuccin.sky
        spacePill.wantsLayer = true
        spacePill.layer?.cornerRadius = 5
        spacePill.layer?.backgroundColor = Catppuccin.surface0.cgColor
        spacePill.layer?.masksToBounds = true
        spacePill.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(spacePill)

        countBadge.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        countBadge.textColor = Catppuccin.yellow
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(countBadge)

        dragAllButton.toolTip = "Click and drag to drop ALL files at once into any AeroSpace workspace"
        dragAllButton.itemsProvider = { [weak self] in
            return self?.model.items ?? []
        }
        dragAllButton.onDragSessionEnded = { [weak self] op in
            if AppSettings.shared.defaultActionIsMove || op == .move {
                self?.model.clear()
            }
        }
        dragAllButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(dragAllButton)

        setupTopButton(copyButton, title: "📋", tooltip: "Copy all files to clipboard (Cmd+V)", color: Catppuccin.teal, action: #selector(copyAllClicked))
        headerView.addSubview(copyButton)

        setupTopButton(closeButton, title: "✕", tooltip: "Hide Basket (press Escape or click)", color: Catppuccin.red, action: #selector(closeClicked))
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: catppuccinBackground.topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: catppuccinBackground.leadingAnchor, constant: 14),
            headerView.trailingAnchor.constraint(equalTo: catppuccinBackground.trailingAnchor, constant: -14),
            headerView.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            spacePill.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            spacePill.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            countBadge.leadingAnchor.constraint(equalTo: spacePill.trailingAnchor, constant: 8),
            countBadge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 26),
            closeButton.heightAnchor.constraint(equalToConstant: 26),

            copyButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -6),
            copyButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 28),
            copyButton.heightAnchor.constraint(equalToConstant: 26),

            dragAllButton.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),
            dragAllButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            dragAllButton.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    private func setupTopButton(_ btn: NSButton, title: String, tooltip: String, color: NSColor, action: Selector) {
        btn.bezelStyle = .regularSquare
        btn.isBordered = false
        btn.target = self
        btn.action = action
        btn.toolTip = tooltip
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 6
        btn.layer?.backgroundColor = Catppuccin.surface0.cgColor

        let attr = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 12, weight: .bold)
            ]
        )
        btn.attributedTitle = attr
        btn.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupEmptyState() {
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        catppuccinBackground.addSubview(emptyView)

        emptyIconLabel.font = NSFont.systemFont(ofSize: 56)
        emptyIconLabel.alignment = .center
        emptyIconLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyIconLabel)

        emptyTitleLabel.font = NSFont.systemFont(ofSize: 16, weight: .heavy)
        emptyTitleLabel.alignment = .center
        emptyTitleLabel.textColor = Catppuccin.text
        emptyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyTitleLabel)

        emptySubtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        emptySubtitleLabel.alignment = .center
        emptySubtitleLabel.textColor = Catppuccin.subtext0
        emptySubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptySubtitleLabel)

        emptyModeHint.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        emptyModeHint.alignment = .center
        emptyModeHint.textColor = Catppuccin.teal
        emptyModeHint.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyModeHint)

        importFinderButton.bezelStyle = .inline
        importFinderButton.isBordered = false
        importFinderButton.wantsLayer = true
        importFinderButton.layer?.cornerRadius = 6
        importFinderButton.layer?.backgroundColor = Catppuccin.surface0.cgColor
        importFinderButton.target = self
        importFinderButton.action = #selector(importFinderClicked)
        importFinderButton.toolTip = "Import selected files from Finder without dragging"

        let attr = NSAttributedString(
            string: "Import Finder Selection",
            attributes: [
                .foregroundColor: Catppuccin.lavender,
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold)
            ]
        )
        importFinderButton.attributedTitle = attr
        importFinderButton.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(importFinderButton)

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            emptyView.leadingAnchor.constraint(equalTo: catppuccinBackground.leadingAnchor, constant: 16),
            emptyView.trailingAnchor.constraint(equalTo: catppuccinBackground.trailingAnchor, constant: -16),
            emptyView.bottomAnchor.constraint(equalTo: catppuccinBackground.bottomAnchor, constant: -58),

            emptyIconLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIconLabel.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 40),

            emptyTitleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIconLabel.bottomAnchor, constant: 12),

            emptySubtitleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 8),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 16),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -16),

            emptyModeHint.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyModeHint.topAnchor.constraint(equalTo: emptySubtitleLabel.bottomAnchor, constant: 10),

            importFinderButton.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            importFinderButton.topAnchor.constraint(equalTo: emptyModeHint.bottomAnchor, constant: 20),
            importFinderButton.heightAnchor.constraint(equalToConstant: 24),
            importFinderButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
        ])
    }

    private func setupPopulatedState() {
        populatedView.translatesAutoresizingMaskIntoConstraints = false
        catppuccinBackground.addSubview(populatedView)

        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        itemsStackView.orientation = .vertical
        itemsStackView.alignment = .width
        itemsStackView.spacing = 6
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.documentView = itemsStackView
        populatedView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            populatedView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            populatedView.leadingAnchor.constraint(equalTo: catppuccinBackground.leadingAnchor, constant: 12),
            populatedView.trailingAnchor.constraint(equalTo: catppuccinBackground.trailingAnchor, constant: -12),
            populatedView.bottomAnchor.constraint(equalTo: catppuccinBackground.bottomAnchor, constant: -58),

            scrollView.topAnchor.constraint(equalTo: populatedView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: populatedView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: populatedView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: populatedView.bottomAnchor),

            itemsStackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            itemsStackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            itemsStackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            itemsStackView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
        ])
    }

    private func setupFooter() {
        footerView.translatesAutoresizingMaskIntoConstraints = false
        catppuccinBackground.addSubview(footerView)

        updateModeButtonTitle()
        modeButton.bezelStyle = .regularSquare
        modeButton.isBordered = false
        modeButton.wantsLayer = true
        modeButton.layer?.cornerRadius = 6
        modeButton.target = self
        modeButton.action = #selector(modeToggleClicked)
        modeButton.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(modeButton)

        setupFooterAction(moveToButton, title: "Move to...", color: Catppuccin.blue, action: #selector(moveClicked))
        footerView.addSubview(moveToButton)

        setupFooterAction(clearButton, title: "Clear", color: Catppuccin.red, action: #selector(clearClicked))
        footerView.addSubview(clearButton)

        hintLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        hintLabel.textColor = Catppuccin.overlay1
        hintLabel.alignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            footerView.bottomAnchor.constraint(equalTo: catppuccinBackground.bottomAnchor, constant: -8),
            footerView.leadingAnchor.constraint(equalTo: catppuccinBackground.leadingAnchor, constant: 12),
            footerView.trailingAnchor.constraint(equalTo: catppuccinBackground.trailingAnchor, constant: -12),
            footerView.heightAnchor.constraint(equalToConstant: 46),

            modeButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            modeButton.topAnchor.constraint(equalTo: footerView.topAnchor),
            modeButton.heightAnchor.constraint(equalToConstant: 24),

            moveToButton.leadingAnchor.constraint(equalTo: modeButton.trailingAnchor, constant: 8),
            moveToButton.topAnchor.constraint(equalTo: footerView.topAnchor),
            moveToButton.heightAnchor.constraint(equalToConstant: 24),

            clearButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            clearButton.topAnchor.constraint(equalTo: footerView.topAnchor),
            clearButton.heightAnchor.constraint(equalToConstant: 24),

            hintLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -2),
        ])
    }

    private func setupFooterAction(_ btn: NSButton, title: String, color: NSColor, action: Selector) {
        btn.bezelStyle = .regularSquare
        btn.isBordered = false
        btn.target = self
        btn.action = action
        btn.wantsLayer = true
        btn.layer?.cornerRadius = 6
        btn.layer?.backgroundColor = Catppuccin.surface0.cgColor

        let attr = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold)
            ]
        )
        btn.attributedTitle = attr
        btn.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupDropCallbacks() {
        containerView.onDraggingEntered = { [weak self] info in
            BasketPanel.shared.cancelAutoHideTimer()
            let isCmd = NSEvent.modifierFlags.contains(.command)
            self?.emptyTitleLabel.stringValue = "Release Mouse to Drop"
            self?.emptyModeHint.stringValue = isCmd ? "⌘ Move Mode: Will move original files" : "Copy Mode: Keeps original files"
            self?.emptyModeHint.textColor = isCmd ? Catppuccin.peach : Catppuccin.teal
            return isCmd ? .move : [.copy, .generic]
        }

        containerView.onDraggingUpdated = { [weak self] info in
            let isCmd = NSEvent.modifierFlags.contains(.command)
            self?.emptyTitleLabel.stringValue = "Release Mouse to Drop"
            self?.emptyModeHint.stringValue = isCmd ? "⌘ Move Mode: Will move original files" : "Copy Mode: Keeps original files"
            self?.emptyModeHint.textColor = isCmd ? Catppuccin.peach : Catppuccin.teal
            return isCmd ? .move : [.copy, .generic]
        }

        containerView.onDraggingExited = { [weak self] _ in
            self?.emptyTitleLabel.stringValue = "Release Mouse to Drop Files"
            self?.emptyModeHint.stringValue = "Default: Copy • Hold ⌘ to Move"
            self?.emptyModeHint.textColor = Catppuccin.teal
        }

        containerView.onPerformDrag = { [weak self] urls, isCmd in
            guard let self = self else { return false }
            let shouldMove = isCmd || AppSettings.shared.defaultActionIsMove
            let added = self.model.add(urls: urls, isMove: shouldMove)
            BasketPanel.shared.cancelAutoHideTimer()
            self.refreshUI()
            return added > 0
        }
    }

    public func refreshUI() {
        countBadge.stringValue = model.summaryString

        // Update AeroSpace Space indicator
        if let ws = AeroSpaceHelper.shared.getFocusedWorkspace() {
            spacePill.stringValue = " [Space: \(ws)] "
            spacePill.isHidden = false
            hintLabel.stringValue = "AeroSpace Workspace [\(ws)] • Stays pinned across all spaces"
        } else {
            spacePill.stringValue = " [All Spaces] "
            spacePill.isHidden = false
            hintLabel.stringValue = "Drop files here • Switch AeroSpace workspace & drag out"
        }

        if model.isEmpty {
            emptyView.isHidden = false
            populatedView.isHidden = true
            dragAllButton.isHidden = true
            copyButton.isHidden = true
            moveToButton.isEnabled = false
            clearButton.isEnabled = false

            emptyTitleLabel.stringValue = "Release Mouse to Drop Files"
            emptyModeHint.stringValue = "Default: Copy • Hold ⌘ to Move"
            emptyModeHint.textColor = Catppuccin.teal

            let selCount = FinderHelper.shared.getSelectedURLs().count
            if selCount > 0 {
                importFinderButton.isHidden = false
                let attr = NSAttributedString(
                    string: "Import \(selCount) Finder Selected Item\(selCount > 1 ? "s" : "")",
                    attributes: [
                        .foregroundColor: Catppuccin.lavender,
                        .font: NSFont.systemFont(ofSize: 11, weight: .semibold)
                    ]
                )
                importFinderButton.attributedTitle = attr
            } else {
                importFinderButton.isHidden = true
            }
        } else {
            emptyView.isHidden = true
            populatedView.isHidden = false
            dragAllButton.isHidden = false
            copyButton.isHidden = false
            moveToButton.isEnabled = true
            clearButton.isEnabled = true

            // Rebuild items stack
            for subview in itemsStackView.arrangedSubviews {
                itemsStackView.removeArrangedSubview(subview)
                subview.removeFromSuperview()
            }

            for item in model.items {
                let row = BasketItemRowView(item: item)
                row.translatesAutoresizingMaskIntoConstraints = false
                row.heightAnchor.constraint(equalToConstant: 74).isActive = true
                row.onRemove = { [weak self] in
                    self?.model.remove(item: item)
                }
                row.onReveal = {
                    FinderHelper.shared.revealInFinder(url: item.url)
                }
                row.onPreview = {
                    QuickLookController.shared.previewSingle(url: item.url)
                }
                row.onToggleMove = { [weak self] in
                    self?.model.toggleMove(item: item)
                }
                row.onDragSessionEnded = { [weak self] op in
                    if item.isMoveOperation || AppSettings.shared.defaultActionIsMove || op == .move {
                        self?.model.remove(item: item)
                    }
                }
                itemsStackView.addArrangedSubview(row)
            }
            itemsStackView.layoutSubtreeIfNeeded()
            scrollView.layoutSubtreeIfNeeded()
        }
    }

    private func updateModeButtonTitle() {
        let isMove = AppSettings.shared.defaultActionIsMove
        let title = isMove ? " Mode: ⌘ Move " : " Mode: Copy "
        let color = isMove ? Catppuccin.peach : Catppuccin.teal

        let attr = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 11, weight: .bold)
            ]
        )
        modeButton.attributedTitle = attr
        modeButton.layer?.backgroundColor = Catppuccin.surface0.cgColor
    }

    // MARK: - Actions

    @objc private func copyAllClicked() {
        model.copyFilesToClipboard()
    }

    @objc private func closeClicked() {
        BasketPanel.shared.hideWithFade()
    }

    @objc private func clearClicked() {
        model.clear()
    }

    @objc private func modeToggleClicked() {
        AppSettings.shared.defaultActionIsMove.toggle()
        model.setAllMove(isMove: AppSettings.shared.defaultActionIsMove)
        updateModeButtonTitle()
    }

    @objc private func importFinderClicked() {
        let urls = FinderHelper.shared.getSelectedURLs()
        if !urls.isEmpty {
            let isCmd = NSEvent.modifierFlags.contains(.command)
            model.add(urls: urls, isMove: isCmd || AppSettings.shared.defaultActionIsMove)
            BasketPanel.shared.cancelAutoHideTimer()
        }
    }

    @objc private func moveClicked() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Move Here"
        panel.message = "Choose destination folder to move basket files:"

        if panel.runModal() == .OK, let targetFolder = panel.url {
            do {
                _ = try model.moveTo(destinationFolder: targetFolder)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to move files"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 { // Spacebar
            let urls = model.items.map { $0.url }
            if !urls.isEmpty {
                QuickLookController.shared.togglePreview(for: urls)
                return
            }
        } else if event.keyCode == 53 { // Escape
            BasketPanel.shared.hideWithFade()
            return
        }
        super.keyDown(with: event)
    }

    // MARK: - BasketModelDelegate

    public func basketDidUpdate(_ model: BasketModel) {
        refreshUI()
    }
}
