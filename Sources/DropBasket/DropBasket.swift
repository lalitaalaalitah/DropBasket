//
//  DropBasket.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa
import Foundation

@main
struct DropBasketApp {
    public static let __version__ = "1.0.0"

    @MainActor
    static func main() {
        CLI.run(arguments: CommandLine.arguments)
    }
}
