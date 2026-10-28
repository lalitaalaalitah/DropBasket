//
//  IPCService.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Foundation
import Cocoa

public final class IPCService: @unchecked Sendable {
    public static let shared = IPCService()

    private let socketPath: String
    private var serverSource: DispatchSourceRead?
    private var serverFd: Int32 = -1

    private init() {
        let user = NSUserName()
        self.socketPath = "/tmp/dropbasket_\(user).sock"
    }

    public func startServer() {
        unlink(socketPath)

        serverFd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFd >= 0 else {
            print("[\(Metadata.appName)] Failed to create IPC socket.")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
        _ = socketPath.withCString { ptr in
            strncpy(&addr.sun_path.0, ptr, maxLen - 1)
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                bind(serverFd, saPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard bindResult == 0 else {
            print("[\(Metadata.appName)] Failed to bind IPC socket at \(socketPath).")
            close(serverFd)
            return
        }

        guard listen(serverFd, 5) == 0 else {
            print("[\(Metadata.appName)] Failed to listen on IPC socket.")
            close(serverFd)
            return
        }

        let source = DispatchSource.makeReadSource(fileDescriptor: serverFd, queue: DispatchQueue.global(qos: .userInitiated))
        source.setEventHandler { [weak self] in
            self?.acceptConnection()
        }
        source.resume()
        serverSource = source
    }

    public func stopServer() {
        serverSource?.cancel()
        if serverFd >= 0 {
            close(serverFd)
            serverFd = -1
        }
        unlink(socketPath)
    }

    private func acceptConnection() {
        var clientAddr = sockaddr_un()
        var len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let clientFd = withUnsafeMutablePointer(to: &clientAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                accept(serverFd, saPtr, &len)
            }
        }
        guard clientFd >= 0 else { return }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(clientFd, &buffer, buffer.count - 1)
        if bytesRead > 0 {
            let commandStr = String(decoding: buffer[0..<bytesRead], as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let response = handleCommand(commandStr)
            _ = response.withCString { ptr in
                write(clientFd, ptr, strlen(ptr))
            }
        }
        close(clientFd)
    }

    private func handleCommand(_ command: String) -> String {
        let parts = command.components(separatedBy: " ")
        guard let action = parts.first?.uppercased() else { return "ERR Empty command\n" }

        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                return executeCommandOnMain(action: action, parts: parts)
            }
        } else {
            return DispatchQueue.main.sync {
                return executeCommandOnMain(action: action, parts: parts)
            }
        }
    }

    @MainActor
    private func executeCommandOnMain(action: String, parts: [String]) -> String {
        switch action {
        case "SHOW":
            let mouseLoc = NSEvent.mouseLocation
            let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
            let cgPoint = CGPoint(x: mouseLoc.x, y: primaryHeight - mouseLoc.y)
            BasketPanel.shared.showNear(cursorPoint: cgPoint)
            return "OK Basket shown\n"

        case "HIDE":
            BasketPanel.shared.hideWithFade()
            return "OK Basket hidden\n"

        case "CLEAR":
            BasketModel.shared.clear()
            return "OK Basket cleared\n"

        case "LIST":
            let items = BasketModel.shared.items
            if items.isEmpty {
                return "EMPTY Basket has no items\n"
            } else {
                let paths = items.map { "\($0.name) (\($0.sizeString)) -> \($0.url.path)" }.joined(separator: "\n")
                return "ITEMS (\(items.count)):\n\(paths)\n"
            }

        case "STATUS":
            let isVis = BasketPanel.shared.isVisible
            let count = BasketModel.shared.count
            let ws = AeroSpaceHelper.shared.getFocusedWorkspace() ?? "Unknown"
            return "STATUS running=true visible=\(isVis) items=\(count) workspace=\(ws)\n"

        case "QUIT", "STOP":
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApplication.shared.terminate(nil)
            }
            return "OK DropBasket terminating\n"

        case "ADD":
            let filePaths = parts.dropFirst()
            var urls: [URL] = []
            for p in filePaths {
                let expanded = (p as NSString).expandingTildeInPath
                let url = URL(fileURLWithPath: expanded)
                if FileManager.default.fileExists(atPath: url.path) {
                    urls.append(url)
                }
            }
            if urls.isEmpty {
                return "ERR No valid file paths provided\n"
            } else {
                let added = BasketModel.shared.add(urls: urls)
                let mouseLoc = NSEvent.mouseLocation
                let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
                let cgPoint = CGPoint(x: mouseLoc.x, y: primaryHeight - mouseLoc.y)
                BasketPanel.shared.showNear(cursorPoint: cgPoint)
                return "OK Added \(added) items\n"
            }

        default:
            return "ERR Unknown action \(action)\n"
        }
    }

    // MARK: - Client

    public func sendCommand(_ command: String) -> (success: Bool, response: String) {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            return (false, "Failed to create client socket.")
        }
        defer { close(fd) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let maxLen = MemoryLayout.size(ofValue: addr.sun_path)
        _ = socketPath.withCString { ptr in
            strncpy(&addr.sun_path.0, ptr, maxLen - 1)
        }

        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                connect(fd, saPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard connectResult == 0 else {
            return (false, "Could not connect to DropBasket daemon. Is it running?")
        }

        let cmdWithNewline = command + "\n"
        _ = cmdWithNewline.withCString { ptr in
            write(fd, ptr, strlen(ptr))
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = read(fd, &buffer, buffer.count - 1)
        if bytesRead > 0 {
            let resp = String(decoding: buffer[0..<bytesRead], as: UTF8.self)
            return (true, resp)
        }
        return (true, "OK")
    }
}
