//
//  AeroSpaceHelper.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Foundation

public final class AeroSpaceHelper: @unchecked Sendable {
    public static let shared = AeroSpaceHelper()

    private let binaryPaths = [
        "/run/current-system/sw/bin/aerospace",
        "/usr/local/bin/aerospace",
        "/opt/homebrew/bin/aerospace",
        "~/.nix-profile/bin/aerospace"
    ]

    private init() {}

    public var aerospaceExecutablePath: String? {
        let fm = FileManager.default
        for path in binaryPaths {
            let expanded = (path as NSString).expandingTildeInPath
            if fm.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }
        // Fallback: search PATH via which
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["aerospace"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                return output
            }
        }
        return nil
    }

    public var isAeroSpaceAvailable: Bool {
        return aerospaceExecutablePath != nil
    }

    private var cachedFocusedWorkspace: String?
    private var lastWorkspaceCheckTime: TimeInterval = 0

    public func getFocusedWorkspace(allowCached: Bool = true) -> String? {
        let now = Date().timeIntervalSinceReferenceDate
        if allowCached, let cached = cachedFocusedWorkspace, (now - lastWorkspaceCheckTime) < 1.0 {
            return cached
        }
        guard let exe = aerospaceExecutablePath else { return cachedFocusedWorkspace }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: exe)
        task.arguments = ["list-workspaces", "--focused"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return cachedFocusedWorkspace }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let res = result, !res.isEmpty {
            cachedFocusedWorkspace = res
            lastWorkspaceCheckTime = now
            return res
        }
        return cachedFocusedWorkspace
    }

    public func listWorkspaces() -> [String] {
        guard let exe = aerospaceExecutablePath else { return [] }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: exe)
        task.arguments = ["list-workspaces", "--all"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return [] }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let out = String(data: data, encoding: .utf8) else { return [] }
        return out.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    public func configSnippet() -> String {
        return """
        # DropBasket configuration for AeroSpace (~/.config/aerospace/aerospace.toml)
        [[on-window-detected]]
        if.app-id = '\(Metadata.bundleIdentifier)'
        run = 'layout floating'
        """
    }
}
