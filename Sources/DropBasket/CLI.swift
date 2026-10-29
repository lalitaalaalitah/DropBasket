//
//  CLI.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import Foundation

public struct CLI {
    public static let __version__ = "1.0.0"

    @MainActor
    public static func run(arguments: [String]) {
        let args = Array(arguments.dropFirst())

        if args.isEmpty {
            handleStartOrSummon()
            return
        }

        let first = args[0]
        switch first {
        case "-v", "--version", "version":
            Metadata.printBanner()
            print("Version: \(Metadata.appVersion)")
            exit(0)

        case "-h", "--help", "help":
            printHelp()
            exit(0)

        case "status", "--status":
            let result = IPCService.shared.sendCommand("STATUS")
            if result.success {
                print("[\(Metadata.appName)] Running:")
                print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
                exit(0)
            } else {
                print("[\(Metadata.appName)] DropBasket is not running.")
                let serviceStat = ServiceManager.status()
                if serviceStat.installed {
                    print("  LaunchAgent is installed. Run 'dropbasket service start' to start it.")
                }
                exit(1)
            }

        case "service":
            let sub = args.dropFirst().first ?? "status"
            switch sub {
            case "install":
                let res = ServiceManager.install()
                print(res.message)
                exit(res.success ? 0 : 1)
            case "uninstall", "remove":
                let res = ServiceManager.uninstall()
                print(res.message)
                exit(res.success ? 0 : 1)
            case "start":
                let res = ServiceManager.start()
                print(res.message)
                exit(res.success ? 0 : 1)
            case "stop":
                let res = ServiceManager.stop()
                print(res.message)
                exit(res.success ? 0 : 1)
            case "restart":
                _ = ServiceManager.stop()
                Thread.sleep(forTimeInterval: 0.5)
                let res = ServiceManager.start()
                print(res.message)
                exit(res.success ? 0 : 1)
            case "status":
                let stat = ServiceManager.status()
                print(stat.message)
                exit(stat.running ? 0 : 1)
            default:
                print("Usage: dropbasket service [install | uninstall | start | stop | restart | status]")
                exit(1)
            }

        case "show", "--show":
            let result = IPCService.shared.sendCommand("SHOW")
            if result.success {
                print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
                exit(0)
            } else {
                print("DropBasket is not running. Starting...")
                startGUIApp()
            }

        case "hide", "--hide":
            let result = IPCService.shared.sendCommand("HIDE")
            print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
            exit(result.success ? 0 : 1)

        case "clear", "--clear":
            let result = IPCService.shared.sendCommand("CLEAR")
            print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
            exit(result.success ? 0 : 1)

        case "list", "--list":
            let result = IPCService.shared.sendCommand("LIST")
            print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
            exit(result.success ? 0 : 1)

        case "add", "--add":
            let paths = args.dropFirst()
            if paths.isEmpty {
                print("Usage: dropbasket add <file1> [file2...]")
                exit(1)
            }
            let absolutePaths = paths.map { (p: String) -> String in
                let expanded = (p as NSString).expandingTildeInPath
                return URL(fileURLWithPath: expanded).path
            }
            let cmd = "ADD " + absolutePaths.joined(separator: " ")
            let result = IPCService.shared.sendCommand(cmd)
            print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
            exit(result.success ? 0 : 1)

        case "stop", "--stop", "quit", "--quit", "kill":
            let result = IPCService.shared.sendCommand("QUIT")
            if result.success {
                print("[\(Metadata.appName)] Terminated DropBasket daemon.")
                exit(0)
            } else {
                print("[\(Metadata.appName)] DropBasket is not currently running.")
                exit(0)
            }

        case "restart", "--restart":
            _ = IPCService.shared.sendCommand("QUIT")
            Thread.sleep(forTimeInterval: 0.4)
            print("[\(Metadata.appName)] Restarting DropBasket...")
            startGUIApp()

        case "daemon", "--daemon", "start", "--start":
            if FileManager.default.fileExists(atPath: ServiceManager.plistURL.path) {
                let res = ServiceManager.start()
                print(res.message)
                exit(res.success ? 0 : 1)
            } else {
                handleStartOrSummon()
            }

        case _ where first.hasPrefix("-psn"):
            // macOS LaunchServices Process Serial Number argument (e.g. -psn_0_123456)
            handleStartOrSummon()

        default:
            let maybeFiles = args.map { (p: String) -> String in
                let expanded = (p as NSString).expandingTildeInPath
                return URL(fileURLWithPath: expanded).path
            }.filter { FileManager.default.fileExists(atPath: $0) }
            if !maybeFiles.isEmpty {
                let cmd = "ADD " + maybeFiles.joined(separator: " ")
                let result = IPCService.shared.sendCommand(cmd)
                print(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
                exit(result.success ? 0 : 1)
            } else {
                print("Unknown command: \(first)")
                print("Run 'dropbasket --help' for usage.")
                exit(1)
            }
        }
    }

    @MainActor
    private static func handleStartOrSummon() {
        // Single instance check: query running daemon status via IPC
        let status = IPCService.shared.sendCommand("STATUS")
        if status.success {
            Metadata.printBanner()
            print("[\(Metadata.appName)] Already running in background.")
            print("[\(Metadata.appName)] Status: \(status.response.trimmingCharacters(in: .whitespacesAndNewlines))")
            _ = IPCService.shared.sendCommand("SHOW")
            print("[\(Metadata.appName)] Summoned floating basket near cursor.")
            print("[\(Metadata.appName)] Hint: Look for the 🧺 icon in your macOS top menu bar!")
            exit(0)
        }

        // Not running yet, start fresh GUI application
        startGUIApp()
    }

    private static func printHelp() {
        Metadata.printBanner()
        let help = """
        USAGE:
          dropbasket [command] [options]

        COMMANDS:
          (no args)             Check if running; summon basket or start background daemon
          add <path>...         Add file(s) or folder(s) to the floating basket
          show                  Show the floating basket window near cursor
          hide                  Hide the floating basket window
          clear                 Clear all items from the basket
          list                  List files currently held in the basket
          status                Check if DropBasket daemon is currently running
          stop / quit           Stop the running background daemon
          restart               Restart the DropBasket daemon
          daemon / start        Start DropBasket as background daemon

        SERVICE MANAGEMENT (LaunchAgent):
          service install       Install and start DropBasket as a permanent background service
          service uninstall     Stop and remove the background service
          service start         Start the installed LaunchAgent service
          service stop          Stop the running LaunchAgent service
          service restart       Restart the background service
          service status        Inspect LaunchAgent service and process status

        OPTIONS:
          -v, --version         Show author metadata and version (__version__ = "\(CLI.__version__)")
          -h, --help            Show this help reference

        AEROSPEACE COMPATIBILITY:
          DropBasket uses NSPanel with .canJoinAllSpaces, remaining visible across
          all virtual AeroSpace workspaces. To prevent AeroSpace from tiling it,
          it automatically runs as a floating accessory panel.

          Optional ~/.config/aerospace/aerospace.toml rule:
            [[on-window-detected]]
            if.app-id = '\(Metadata.bundleIdentifier)'
            run = 'layout floating'

        GESTURE TRIGGER:
          The basket stays hidden and appears automatically when you select files,
          drag them, and gently shake the mouse cursor!
          A 🧺 icon in the macOS top menu bar provides live item counts and actions.
        """
        print(help)
    }

    @MainActor
    private static func startGUIApp() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
