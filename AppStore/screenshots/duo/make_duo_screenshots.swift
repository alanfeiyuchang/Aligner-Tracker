// Builds the iPhone Duo App Store images from the raw simulator captures in
// raw/. Same look as the 6.9-inch and 6.5-inch sets: teal gradient, white
// headline and subtitle, the screen on a rounded card that runs off the bottom.
//
//   cd AppStore/screenshots/duo && swift make_duo_screenshots.swift
//
// Each image is the native pixel size of the screen it shows:
//   outer/            1398 × 2034   folded, 5.4-inch outer screen
//   inner/            2007 × 2853   unfolded, 7.6-inch inner screen, upright
//   inner-landscape/  2853 × 2007   unfolded, held wide (two-column layouts)
// How the raw captures are taken is in docs/iphone-duo.md.

import AppKit

struct Shot { let file, name, headline, subtitle: String }

let shots = [
    Shot(file: "home", name: "1_home", headline: "Track every hour\nyou wear", subtitle: "Hit your 22-hour goal, every day"),
    Shot(file: "history", name: "2_history", headline: "See your streak\n& daily progress", subtitle: "Color-coded calendar and averages"),
    Shot(file: "settings", name: "3_settings", headline: "Never miss a\ntray change", subtitle: "Smart reminders on your schedule"),
    Shot(file: "diary", name: "4_diary", headline: "A photo diary\nof your smile", subtitle: "One entry for every tray"),
]

func render(set: String, shot: Shot) throws {
    let here = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let rawURL = here.appendingPathComponent("raw/\(set)/\(shot.file).png")
    guard let raw = NSBitmapImageRep(data: try Data(contentsOf: rawURL))?.cgImage else { return }
    let W = CGFloat(raw.width), H = CGFloat(raw.height)
    let wide = W > H

    let ctx = CGContext(data: nil, width: raw.width, height: raw.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)

    // Background: #4ECDC4 at the top, darkening towards the bottom.
    let gradient = CGGradient(colorsSpace: nil, colors: [
        CGColor(srgbRed: 0x4E / 255, green: 0xCD / 255, blue: 0xC4 / 255, alpha: 1),
        CGColor(srgbRed: 0x2A / 255, green: 0x78 / 255, blue: 0x73 / 255, alpha: 1),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: H), end: .zero, options: [])

    // Text block, centred, measured so the subtitle never touches the headline.
    // A wide canvas has little height to spare, so its headline is one line.
    let headlineSize = wide ? H * 0.068 : W * 0.086
    let subtitleSize = headlineSize * 0.42
    let centred = NSMutableParagraphStyle()
    centred.alignment = .center
    centred.lineHeightMultiple = 0.95
    let headline = NSAttributedString(string: wide ? shot.headline.replacingOccurrences(of: "\n", with: " ") : shot.headline, attributes: [
        .font: NSFont.systemFont(ofSize: headlineSize, weight: .regular),
        .foregroundColor: NSColor.white, .paragraphStyle: centred, .kern: -headlineSize * 0.02,
    ])
    let subtitle = NSAttributedString(string: shot.subtitle, attributes: [
        .font: NSFont.systemFont(ofSize: subtitleSize, weight: .regular),
        .foregroundColor: NSColor.white.withAlphaComponent(0.95), .paragraphStyle: centred,
    ])
    let box = CGSize(width: W * 0.9, height: H)
    let headlineHeight = ceil(headline.boundingRect(with: box, options: [.usesLineFragmentOrigin]).height)
    let subtitleHeight = ceil(subtitle.boundingRect(with: box, options: [.usesLineFragmentOrigin]).height)
    let top = H * (wide ? 0.055 : 0.05)
    let gap = headlineSize * 0.22
    headline.draw(with: CGRect(x: W * 0.05, y: H - top - headlineHeight, width: box.width, height: headlineHeight),
                  options: [.usesLineFragmentOrigin])
    subtitle.draw(with: CGRect(x: W * 0.05, y: H - top - headlineHeight - gap - subtitleHeight, width: box.width, height: subtitleHeight),
                  options: [.usesLineFragmentOrigin])

    // The screen, on a rounded card with a soft shadow, running off the bottom.
    let cardTop = top + headlineHeight + gap + subtitleHeight + headlineSize * 0.6
    let cardWidth = W * (wide ? 0.74 : 0.80)
    let cardHeight = cardWidth * H / W
    let card = CGRect(x: (W - cardWidth) / 2, y: H - cardTop - cardHeight, width: cardWidth, height: cardHeight)
    let path = CGPath(roundedRect: card, cornerWidth: cardWidth * 0.075, cornerHeight: cardWidth * 0.075, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: W * 0.03, color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(path)
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.interpolationQuality = .high
    ctx.draw(raw, in: card)
    ctx.restoreGState()

    let out = here.appendingPathComponent("\(set)/\(shot.name).png")
    try FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
    // No alpha channel: App Store Connect rejects screenshots that have one.
    let opaque = CGContext(data: nil, width: raw.width, height: raw.height, bitsPerComponent: 8, bytesPerRow: 0,
                           space: CGColorSpace(name: CGColorSpace.sRGB)!,
                           bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    opaque.draw(ctx.makeImage()!, in: CGRect(x: 0, y: 0, width: W, height: H))
    try NSBitmapImageRep(cgImage: opaque.makeImage()!).representation(using: .png, properties: [:])!.write(to: out)
    print("\(set)/\(shot.name).png  \(raw.width) × \(raw.height)")
}

for set in ["outer", "inner", "inner-landscape"] {
    for shot in shots { try render(set: set, shot: shot) }
}
