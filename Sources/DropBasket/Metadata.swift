//
//  Metadata.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Foundation

public struct Metadata {
    public static let author = "lalitaalaalitah"
    public static let website = "https://www.lalitaalaalitah.com"
    public static let github = "https://github.com/lalitaalaalitah"
    public static let appName = "DropBasket"
    public static let appVersion = "1.0.0"
    public static let bundleIdentifier = "com.lalitaalaalitah.DropBasket"
    public static let description = "Floating drag-and-drop basket companion for AeroSpace on macOS"

    public static func printBanner() {
        let banner = """
        ================================================================================
          \(appName) v\(appVersion)
          Author: \(author)
          Website: \(website)
          GitHub Profile: \(github)
          Description: \(description)
        ================================================================================
        """
        print(banner)
    }

    public static func versionString() -> String {
        return "\(appName) v\(appVersion) by \(author) (\(github))"
    }
}

