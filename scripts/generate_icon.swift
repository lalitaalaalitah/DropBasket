#!/usr/bin/env swift
//
//  generate_icon.swift
//  DropBasket Icon Generator
//
//  Author: lalitaalaalitah
//  Website: https://www.lalitaalaalitah.com
//  GitHub Profile: https://github.com/lalitaalaalitah
//

import Cocoa

let __version__ = "1.0.0"

if CommandLine.arguments.contains("--version") {
    print("================================================================================")
    print("  generate_icon.swift v\(__version__)")
    print("  Author: lalitaalaalitah")
    print("  Website: https://www.lalitaalaalitah.com")
    print("  GitHub Profile: https://github.com/lalitaalaalitah")
    print("================================================================================")
    exit(0)
}

func drawIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237 // Apple squircle ratio

    // Squircle background path
    let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.04, dy: size * 0.04), xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background: Deep indigo to vibrant violet-blue
    let gradient = NSGradient(
        starting: NSColor(red: 0.12, green: 0.15, blue: 0.32, alpha: 1.0),
        ending: NSColor(red: 0.28, green: 0.42, blue: 0.85, alpha: 1.0)
    )
    gradient?.draw(in: bgPath, angle: -45)

    // Subtle inner border
    NSColor.white.withAlphaComponent(0.25).setStroke()
    bgPath.lineWidth = size * 0.015
    bgPath.stroke()

    // Basket Emoji or Icon centered
    let basketStr = "🧺" as NSString
    let fontSize = size * 0.52
    let font = NSFont.systemFont(ofSize: fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font
    ]
    let strSize = basketStr.size(withAttributes: attrs)
    let strRect = NSRect(
        x: (size - strSize.width) / 2.0,
        y: (size - strSize.height) / 2.0 - (size * 0.02),
        width: strSize.width,
        height: strSize.height
    )
    basketStr.draw(in: strRect, withAttributes: attrs)

    img.unlockFocus()
    return img
}

let iconsetPath = "/tmp/DropBasket.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (base, scale) in sizes {
    let px = base * scale
    let img = drawIcon(size: CGFloat(px))
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    let filename = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
    let fileURL = URL(fileURLWithPath: "\(iconsetPath)/\(filename)")
    try? png.write(to: fileURL)
}

let outDir = "Resources"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let icnsPath = "\(outDir)/AppIcon.icns"

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try? task.run()
task.waitUntilExit()

try? FileManager.default.removeItem(atPath: iconsetPath)
print("Generated AppIcon.icns successfully at \(icnsPath)")

