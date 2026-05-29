#!/usr/bin/env swift
// Renders the same 🌸 blossom used in the Flutter app (system emoji).
import AppKit

let foregroundOnly = CommandLine.arguments.contains("--foreground")
let outPath: String = {
    if let i = CommandLine.arguments.firstIndex(of: "--out"),
       CommandLine.arguments.count > i + 1 {
        return CommandLine.arguments[i + 1]
    }
    return foregroundOnly ? "app_icon_foreground_1024.png" : "app_icon_master_1024.png"
}()

let size: CGFloat = 1024
let rose100 = NSColor(red: 252 / 255, green: 231 / 255, blue: 243 / 255, alpha: 1)
let rose300 = NSColor(red: 249 / 255, green: 168 / 255, blue: 212 / 255, alpha: 1)

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

if !foregroundOnly, let ctx = NSGraphicsContext.current?.cgContext {
    let colors = [rose100.cgColor, rose300.cgColor] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: size / 2, y: size),
            end: CGPoint(x: size / 2, y: 0),
            options: []
        )
    }
}

let blossom = "🌸" as NSString
let fontSize: CGFloat = foregroundOnly ? 520 : 620
let font = NSFont.systemFont(ofSize: fontSize)
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .paragraphStyle: paragraph,
]
let textSize = blossom.size(withAttributes: attrs)
let textRect = NSRect(
    x: (size - textSize.width) / 2,
    y: (size - textSize.height) / 2 - size * 0.04,
    width: textSize.width,
    height: textSize.height
)
blossom.draw(in: textRect, withAttributes: attrs)

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: outPath)
try png.write(to: url)
print("wrote \(url.path)")
