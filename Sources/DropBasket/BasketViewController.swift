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
    public var onDraggingExited: ((NSDraggingInfo?) -> Void)?
    public var onPerformDrag: (([URL]) -> Bool)?

    private var isHighlighted: Bool = false

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, .URL])
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let op = onDraggingEntered?(sender) ?? [.copy, .generic]
        setHighlight(true)
        return op
    }

    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return [.copy, .generic]
    }

    public override func draggingExited(_ sender: NSDraggingInfo?) {
        setHighlight(false)
        onDraggingExited?(sender)
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        setHighlight(false)
        let pb = sender.draggingPasteboard
        var urls: [URL] = []

        if let items = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls.append(contentsOf: items)
        } else if let propList = pb.propertyList(forType: .init("NSFilenamesPboardType")) as? [String] {
            for p in propList {
                urls.append(URL(fileURLWithPath: p))
            }
        }

        if !urls.isEmpty {
            return onPerformDrag?(urls) ?? false
        }
        return false
    }

    private func setHighlight(_ highlighted: Bool) {
        isHighlighted = highlighted
        needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 16, yRadius: 16)
            path.lineWidth = 3.0
            NSColor.controlAccentColor.setStroke()
            path.stroke()
        }
    }
}

@MainActor
public class BasketViewController: NSViewController, BasketModelDelegate {
    private let model = BasketModel.shared
    private let containerView = BasketRootDropView()
    private let visualEffectView = NSVisualEffectView()

    // Header views
    private let headerView = NSView()
    private let titleLabel = NSTextField(labelWithString: "🧺 DropBasket")
    private let countBadge = NSTextField(labelWithString: "")
    private let dragAllButton = DraggableAllButton(title: "📦 Drag All", target: nil, action: nil)
    private let copyButton = NSButton()
    private let closeButton = NSButton()

    // Empty state views
    private let emptyView = NSView()
    private let emptyIconLabel = NSTextField(labelWithString: "🧺")
    private let emptyTitleLabel = NSTextField(labelWithString: "Drop Files to Basket")
    private let emptySubtitleLabel = NSTextField(labelWithString: "Shake cursor with files to summon anywhere\nSwitch AeroSpace workspace & drag out")
    private let collectFinderButton = NSButton()

    // Populated state views
    private let populatedView = NSView()
    private let scrollView = NSScrollView()
    private let itemsStackView = NSStackView()

    // Footer views
    private let footerView = NSView()
    private let modeButton = NSButton()
    private let moveToButton = NSButton()
    private let clearButton = NSButton()
    private let hintLabel = NSTextField(labelWithString: "AeroSpace: Windows stay across workspaces")

    public override func loadView() {
        containerView.frame = NSRect(x: 0, y: 0, width: 360, height: 420)
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
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1.0
        visualEffectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        containerView.addSubview(visualEffectView)
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(headerView)

        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        countBadge.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        countBadge.textColor = .secondaryLabelColor
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(countBadge)

        // Drag All button
        dragAllButton.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        dragAllButton.bezelStyle = .inline
        dragAllButton.toolTip = "Click and drag to drop ALL files at once into any destination"
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

        // Copy button
        copyButton.title = "📋"
        copyButton.toolTip = "Copy all files to clipboard (Cmd+V to paste)"
        copyButton.bezelStyle = .texturedRounded
        copyButton.target = self
        copyButton.action = #selector(copyAllClicked)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(copyButton)

        // Close button
        closeButton.title = "✕"
        closeButton.toolTip = "Hide Basket (press Escape or click)"
        closeButton.bezelStyle = .texturedRounded
        closeButton.target = self
        closeButton.action = #selector(closeClicked)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            countBadge.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            countBadge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),

            copyButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
            copyButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 28),

            dragAllButton.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -6),
            dragAllButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
        ])
    }

    private func setupEmptyState() {
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(emptyView)

        emptyIconLabel.font = NSFont.systemFont(ofSize: 44)
        emptyIconLabel.alignment = .center
        emptyIconLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyIconLabel)

        emptyTitleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        emptyTitleLabel.alignment = .center
        emptyTitleLabel.textColor = .labelColor
        emptyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptyTitleLabel)

        emptySubtitleLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        emptySubtitleLabel.alignment = .center
        emptySubtitleLabel.textColor = .secondaryLabelColor
        emptySubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(emptySubtitleLabel)

        collectFinderButton.title = "Collect Finder Selection"
        collectFinderButton.bezelStyle = .rounded
        collectFinderButton.target = self
        collectFinderButton.action = #selector(collectFinderClicked)
        collectFinderButton.translatesAutoresizingMaskIntoConstraints = false
        emptyView.addSubview(collectFinderButton)

        NSLayoutConstraint.activate([
            emptyView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            emptyView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 16),
            emptyView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -16),
            emptyView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -56),

            emptyIconLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIconLabel.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 28),

            emptyTitleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIconLabel.bottomAnchor, constant: 10),

            emptySubtitleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 8),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 12),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -12),

            collectFinderButton.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            collectFinderButton.topAnchor.constraint(equalTo: emptySubtitleLabel.bottomAnchor, constant: 16),
        ])
    }

    private func setupPopulatedState() {
        populatedView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(populatedView)

        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        itemsStackView.orientation = .vertical
        itemsStackView.spacing = 4
        itemsStackView.alignment = .leading
        itemsStackView.translatesAutoresizingMaskIntoConstraints = false

        let clipView = NSClipView()
        clipView.drawsBackground = false
        clipView.documentView = itemsStackView
        scrollView.contentView = clipView

        populatedView.addSubview(scrollView)

        NSLayoutConstraint.activate([
            populatedView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            populatedView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 10),
            populatedView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -10),
            populatedView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -56),

            scrollView.topAnchor.constraint(equalTo: populatedView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: populatedView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: populatedView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: populatedView.bottomAnchor),

            itemsStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            itemsStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            itemsStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
        ])
    }

    private func setupFooter() {
        footerView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.addSubview(footerView)

        updateModeButtonTitle()
        modeButton.bezelStyle = .texturedRounded
        modeButton.font = NSFont.systemFont(ofSize: 11)
        modeButton.target = self
        modeButton.action = #selector(modeToggleClicked)
        modeButton.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(modeButton)

        moveToButton.title = "Move to..."
        moveToButton.bezelStyle = .texturedRounded
        moveToButton.font = NSFont.systemFont(ofSize: 11)
        moveToButton.target = self
        moveToButton.action = #selector(moveClicked)
        moveToButton.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(moveToButton)

        clearButton.title = "Clear"
        clearButton.bezelStyle = .texturedRounded
        clearButton.font = NSFont.systemFont(ofSize: 11)
        clearButton.target = self
        clearButton.action = #selector(clearClicked)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(clearButton)

        hintLabel.font = NSFont.systemFont(ofSize: 10)
        hintLabel.textColor = .tertiaryLabelColor
        hintLabel.alignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            footerView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -8),
            footerView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 10),
            footerView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -10),
            footerView.heightAnchor.constraint(equalToConstant: 44),

            modeButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            modeButton.topAnchor.constraint(equalTo: footerView.topAnchor),

            moveToButton.leadingAnchor.constraint(equalTo: modeButton.trailingAnchor, constant: 6),
            moveToButton.topAnchor.constraint(equalTo: footerView.topAnchor),

            clearButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            clearButton.topAnchor.constraint(equalTo: footerView.topAnchor),

            hintLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -2),
        ])
    }

    private func setupDropCallbacks() {
        containerView.onDraggingEntered = { _ in
            BasketPanel.shared.cancelAutoHideTimer()
            return [.copy, .generic]
        }

        containerView.onDraggingExited = { [weak self] _ in
            if self?.model.isEmpty == true {
                BasketPanel.shared.startAutoHideTimer()
            }
        }

        containerView.onPerformDrag = { [weak self] urls in
            guard let self = self else { return false }
            let added = self.model.add(urls: urls)
            BasketPanel.shared.cancelAutoHideTimer()
            return added > 0
        }
    }

    public func refreshUI() {
        countBadge.stringValue = model.summaryString

        if model.isEmpty {
            emptyView.isHidden = false
            populatedView.isHidden = true
            dragAllButton.isHidden = true
            copyButton.isHidden = true
            moveToButton.isEnabled = false
            clearButton.isEnabled = false

            let selCount = FinderHelper.shared.getSelectedURLs().count
            if selCount > 0 {
                collectFinderButton.isHidden = false
                collectFinderButton.title = "Collect \(selCount) Finder Item\(selCount > 1 ? "s" : "")"
            } else {
                collectFinderButton.isHidden = true
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
                row.widthAnchor.constraint(equalTo: itemsStackView.widthAnchor).isActive = true
                row.onRemove = { [weak self] in
                    self?.model.remove(item: item)
                }
                row.onReveal = {
                    FinderHelper.shared.revealInFinder(url: item.url)
                }
                row.onPreview = {
                    QuickLookController.shared.previewSingle(url: item.url)
                }
                row.onDragSessionEnded = { [weak self] op in
                    if AppSettings.shared.defaultActionIsMove || op == .move {
                        self?.model.remove(item: item)
                    }
                }
                itemsStackView.addArrangedSubview(row)
            }
        }

        // Update AeroSpace indicator
        if let ws = AeroSpaceHelper.shared.getFocusedWorkspace() {
            hintLabel.stringValue = "AeroSpace Workspace [\(ws)] • Stays across spaces"
        } else {
            hintLabel.stringValue = "Drop files here • Drag out in any AeroSpace workspace"
        }
    }

    private func updateModeButtonTitle() {
        let isMove = AppSettings.shared.defaultActionIsMove
        modeButton.title = isMove ? "Mode: Move" : "Mode: Copy"
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
        updateModeButtonTitle()
    }

    @objc private func collectFinderClicked() {
        let urls = FinderHelper.shared.getSelectedURLs()
        if !urls.isEmpty {
            model.add(urls: urls)
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

    // Spacebar to trigger Quick Look
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
        if model.isEmpty {
            BasketPanel.shared.startAutoHideTimer()
        }
    }
}
