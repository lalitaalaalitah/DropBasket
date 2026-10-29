//
//  ServiceManager.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Foundation

public struct ServiceManager {
    public static let serviceLabel = "com.lalitaalaalitah.DropBasket"

    public static var plistURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(serviceLabel).plist")
    }

    public static func findAppBinaryPath() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let possiblePaths = [
            home.appendingPathComponent("Applications/DropBasket.app/Contents/MacOS/DropBasket").path,
            "/Applications/DropBasket.app/Contents/MacOS/DropBasket",
            home.appendingPathComponent(".local/bin/dropbasket").path
        ]
        return possiblePaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }

    public static func generatePlistContent(binaryPath: String) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(serviceLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(binaryPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ProcessType</key>
            <string>Interactive</string>
            <key>StandardOutPath</key>
            <string>/tmp/dropbasket.stdout.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/dropbasket.stderr.log</string>
        </dict>
        </plist>
        """
    }

    @discardableResult
    public static func install() -> (success: Bool, message: String) {
        guard let binPath = findAppBinaryPath() else {
            return (false, "Could not locate installed DropBasket application or binary.")
        }

        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let content = generatePlistContent(binaryPath: binPath)
        do {
            try content.write(to: plistURL, atomically: true, encoding: .utf8)
        } catch {
            return (false, "Failed to write LaunchAgent plist: \(error.localizedDescription)")
        }

        // Unload first if previously loaded to ensure clean state
        _ = runCommand("/bin/launchctl", arguments: ["unload", plistURL.path])

        let loadResult = runCommand("/bin/launchctl", arguments: ["load", "-w", plistURL.path])
        if loadResult.exitCode == 0 {
            return (true, "LaunchAgent installed and started successfully:\n  \(plistURL.path)")
        } else {
            return (false, "Wrote plist but launchctl load failed:\n  \(loadResult.output)")
        }
    }

    @discardableResult
    public static func uninstall() -> (success: Bool, message: String) {
        if FileManager.default.fileExists(atPath: plistURL.path) {
            _ = runCommand("/bin/launchctl", arguments: ["unload", "-w", plistURL.path])
            try? FileManager.default.removeItem(at: plistURL)
            _ = IPCService.shared.sendCommand("QUIT")
            return (true, "LaunchAgent service uninstalled successfully.")
        } else {
            _ = IPCService.shared.sendCommand("QUIT")
            return (true, "LaunchAgent service was not installed.")
        }
    }

    @discardableResult
    public static func start() -> (success: Bool, message: String) {
        if !FileManager.default.fileExists(atPath: plistURL.path) {
            return install()
        }
        let result = runCommand("/bin/launchctl", arguments: ["load", "-w", plistURL.path])
        if result.exitCode == 0 {
            return (true, "DropBasket service started via launchctl.")
        } else {
            return (false, "Failed to start service: \(result.output)")
        }
    }

    @discardableResult
    public static func stop() -> (success: Bool, message: String) {
        if FileManager.default.fileExists(atPath: plistURL.path) {
            let result = runCommand("/bin/launchctl", arguments: ["unload", plistURL.path])
            _ = IPCService.shared.sendCommand("QUIT")
            return (result.exitCode == 0, result.exitCode == 0 ? "DropBasket service stopped." : result.output)
        } else {
            let ipc = IPCService.shared.sendCommand("QUIT")
            return (ipc.success, ipc.response)
        }
    }

    public static func status() -> (installed: Bool, running: Bool, message: String) {
        let isInstalled = FileManager.default.fileExists(atPath: plistURL.path)
        let ipc = IPCService.shared.sendCommand("STATUS")
        let isRunning = ipc.success

        var desc = "DropBasket Background Service Status:\n"
        desc += "  • LaunchAgent: \(isInstalled ? "Installed (\(plistURL.path))" : "Not installed")\n"
        desc += "  • Daemon:      \(isRunning ? "🟢 RUNNING" : "⚪ STOPPED")\n"
        if isRunning {
            desc += "  • Details:     \(ipc.response.trimmingCharacters(in: .whitespacesAndNewlines))\n"
        }
        return (isInstalled, isRunning, desc)
    }

    public static func runCommand(_ launchPath: String, arguments: [String]) -> (exitCode: Int32, output: String) {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self)
            return (process.terminationStatus, output)
        } catch {
            return (-1, error.localizedDescription)
        }
    }
}
