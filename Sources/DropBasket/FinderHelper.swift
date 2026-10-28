//
//  FinderHelper.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa

@MainActor
public class FinderHelper {
    public static let shared = FinderHelper()

    private init() {}

    public var isFinderFrontmost: Bool {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"
    }

    public func getSelectedURLs() -> [URL] {
        let scriptSource = """
        tell application "Finder"
            try
                set sel to selection as alias list
                set posixList to {}
                repeat with anItem in sel
                    set end of posixList to POSIX path of anItem
                end repeat
                return posixList
            on error
                return {}
            end try
        end tell
        """

        guard let script = NSAppleScript(source: scriptSource) else { return [] }
        var errorDict: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorDict)
        if errorDict != nil {
            return []
        }

        var urls: [URL] = []
        let count = descriptor.numberOfItems
        if count > 0 {
            for i in 1...count {
                if let item = descriptor.atIndex(i)?.stringValue {
                    let path = item.hasSuffix("/") && item != "/" ? String(item.dropLast()) : item
                    let url = URL(fileURLWithPath: path)
                    urls.append(url)
                }
            }
        }
        return urls
    }

    public func revealInFinder(url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
