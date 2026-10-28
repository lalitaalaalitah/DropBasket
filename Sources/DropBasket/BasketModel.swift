//
//  BasketModel.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import UniformTypeIdentifiers

public struct BasketItem: Identifiable, Equatable, @unchecked Sendable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let extensionString: String
    public let kind: String
    public let icon: NSImage
    public let sizeBytes: Int64
    public let sizeString: String
    public let directoryName: String
    public let modificationDateString: String
    public let isDirectory: Bool
    public var isMoveOperation: Bool
    public let dateAdded: Date

    public init(url: URL, isMove: Bool = false) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.dateAdded = Date()
        self.isMoveOperation = isMove

        let ext = url.pathExtension.uppercased()
        self.extensionString = ext.isEmpty ? (url.hasDirectoryPath ? "DIR" : "FILE") : ext

        let ws = NSWorkspace.shared
        self.icon = ws.icon(forFile: url.path)
        self.icon.size = NSSize(width: 40, height: 40)

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue

        self.directoryName = url.deletingLastPathComponent().lastPathComponent

        // Fetch rich resource values
        var size: Int64 = 0
        var typeDesc = isDir.boolValue ? "Folder" : "File"
        var modDateStr = "Unknown"

        if let rv = try? url.resourceValues(forKeys: [.localizedTypeDescriptionKey, .fileSizeKey, .contentModificationDateKey, .totalFileSizeKey]) {
            if let desc = rv.localizedTypeDescription, !desc.isEmpty {
                typeDesc = desc
            }
            if let fileSize = rv.totalFileSize ?? rv.fileSize {
                size = Int64(fileSize)
            }
            if let modDate = rv.contentModificationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.doesRelativeDateFormatting = true
                modDateStr = formatter.string(from: modDate)
            }
        } else if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
            size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
            if let modDate = attrs[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.doesRelativeDateFormatting = true
                modDateStr = formatter.string(from: modDate)
            }
        }

        self.sizeBytes = size
        self.sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        self.kind = typeDesc
        self.modificationDateString = modDateStr
    }

    public static func == (lhs: BasketItem, rhs: BasketItem) -> Bool {
        return lhs.url == rhs.url
    }
}

@MainActor
public protocol BasketModelDelegate: AnyObject {
    func basketDidUpdate(_ model: BasketModel)
}

@MainActor
public class BasketModel {
    public static let shared = BasketModel()

    public weak var delegate: BasketModelDelegate?
    public private(set) var items: [BasketItem] = []

    public var count: Int {
        return items.count
    }

    public var isEmpty: Bool {
        return items.isEmpty
    }

    public var totalSizeString: String {
        let total = items.reduce(Int64(0)) { $0 + $1.sizeBytes }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    public var summaryString: String {
        if items.isEmpty {
            return "Empty"
        } else if items.count == 1 {
            return "1 item (\(totalSizeString))"
        } else {
            return "\(items.count) items (\(totalSizeString))"
        }
    }

    private init() {}

    @discardableResult
    public func add(urls: [URL], isMove: Bool = false) -> Int {
        var addedCount = 0
        for url in urls {
            let standardURL = url.standardizedFileURL
            if let idx = items.firstIndex(where: { $0.url.path == standardURL.path }) {
                // Update move flag if specified
                if isMove {
                    items[idx].isMoveOperation = true
                }
            } else {
                let item = BasketItem(url: standardURL, isMove: isMove)
                items.append(item)
                addedCount += 1
            }
        }

        if addedCount > 0 {
            if AppSettings.shared.soundEffects {
                NSSound(named: "Pop")?.play()
            }
            delegate?.basketDidUpdate(self)
        }
        return addedCount
    }

    public func remove(item: BasketItem) {
        items.removeAll(where: { $0.id == item.id })
        delegate?.basketDidUpdate(self)
    }

    public func remove(at index: Int) {
        guard index >= 0 && index < items.count else { return }
        items.remove(at: index)
        delegate?.basketDidUpdate(self)
    }

    public func toggleMove(item: BasketItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isMoveOperation.toggle()
            delegate?.basketDidUpdate(self)
        }
    }

    public func setAllMove(isMove: Bool) {
        for i in 0..<items.count {
            items[i].isMoveOperation = isMove
        }
        delegate?.basketDidUpdate(self)
    }

    public func clear() {
        guard !items.isEmpty else { return }
        items.removeAll()
        if AppSettings.shared.soundEffects {
            NSSound(named: "Basso")?.play()
        }
        delegate?.basketDidUpdate(self)
    }

    public func copyFilesToClipboard() {
        guard !items.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        let nsUrls = items.map { $0.url as NSURL }
        pb.writeObjects(nsUrls)
        if AppSettings.shared.soundEffects {
            NSSound(named: "Tink")?.play()
        }
    }

    public func copyPathsToClipboard() {
        guard !items.isEmpty else { return }
        let paths = items.map { $0.url.path }.joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(paths, forType: .string)
        if AppSettings.shared.soundEffects {
            NSSound(named: "Tink")?.play()
        }
    }

    public func moveTo(destinationFolder: URL) throws -> [URL] {
        var movedURLs: [URL] = []
        let fm = FileManager.default

        for item in items {
            let targetURL = destinationFolder.appendingPathComponent(item.name)
            var finalTarget = targetURL
            var counter = 1
            while fm.fileExists(atPath: finalTarget.path) {
                let baseName = (item.name as NSString).deletingPathExtension
                let ext = (item.name as NSString).pathExtension
                let newName = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
                finalTarget = destinationFolder.appendingPathComponent(newName)
                counter += 1
            }

            try fm.moveItem(at: item.url, to: finalTarget)
            movedURLs.append(finalTarget)
        }

        clear()
        if AppSettings.shared.soundEffects {
            NSSound(named: "Purr")?.play()
        }
        return movedURLs
    }
}
