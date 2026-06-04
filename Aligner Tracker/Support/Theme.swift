//
//  Theme.swift
//  Aligner Tracker
//
//  App-wide colors and shared formatting helpers.
//

import SwiftUI

enum Theme {
    /// Primary soft teal/mint — #4ECDC4.
    static let teal = Color(red: 0x4E / 255, green: 0xCD / 255, blue: 0xC4 / 255)
    static let tealDark = Color(red: 0x36 / 255, green: 0x9E / 255, blue: 0x97 / 255)

    static let goalGreen = Color(red: 0x3C / 255, green: 0xB3 / 255, blue: 0x71 / 255)
    static let goalYellow = Color(red: 0xF2 / 255, green: 0xC0 / 255, blue: 0x37 / 255)
    static let goalRed = Color(red: 0xE5 / 255, green: 0x57 / 255, blue: 0x53 / 255)

    static let ringGradient = AngularGradient(
        colors: [teal, tealDark, teal],
        center: .center
    )
}

enum WearFormatter {
    /// Compact "18h 32m" style used widely in the UI.
    static func hm(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        return "\(h)h \(m)m"
    }

    /// "18:32:05" style for the live session clock.
    static func clock(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Compact duration that keeps seconds for short spans: "1h 5m", "12m", "45s".
    static func short(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(s)s"
    }
}
