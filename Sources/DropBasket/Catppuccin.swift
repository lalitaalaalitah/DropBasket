//
//  Catppuccin.swift
//  DropBasket
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa

public struct Catppuccin {
    // Catppuccin Mocha Palette
    public static let rosewater = NSColor(hex: "#f5e0dc")
    public static let flamingo  = NSColor(hex: "#f2cdcd")
    public static let pink      = NSColor(hex: "#f5c2e7")
    public static let mauve     = NSColor(hex: "#cba6f7")
    public static let red       = NSColor(hex: "#f38ba8")
    public static let maroon    = NSColor(hex: "#eba0ac")
    public static let peach     = NSColor(hex: "#fab387")
    public static let yellow    = NSColor(hex: "#f9e2af")
    public static let green     = NSColor(hex: "#a6e3a1")
    public static let teal      = NSColor(hex: "#94e2d5")
    public static let sapphire  = NSColor(hex: "#74c7ec")
    public static let sky       = NSColor(hex: "#89dceb")
    public static let blue      = NSColor(hex: "#89b4fa")
    public static let lavender  = NSColor(hex: "#b4befe")
    public static let text      = NSColor(hex: "#cdd6f4")
    public static let subtext1  = NSColor(hex: "#bac2de")
    public static let subtext0  = NSColor(hex: "#a6adc8")
    public static let overlay2  = NSColor(hex: "#9399b2")
    public static let overlay1  = NSColor(hex: "#7f849c")
    public static let overlay0  = NSColor(hex: "#6c7086")
    public static let surface2  = NSColor(hex: "#585b70")
    public static let surface1  = NSColor(hex: "#45475a")
    public static let surface0  = NSColor(hex: "#313244")
    public static let base      = NSColor(hex: "#1e1e2e")
    public static let mantle    = NSColor(hex: "#181825")
    public static let crust     = NSColor(hex: "#11111b")
}

extension NSColor {
    public convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.removeFirst()
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }
}

