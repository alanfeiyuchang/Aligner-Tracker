//
//  WidgetSupport.swift
//  AlignerTrackerWidget
//
//  Shared colors for the widget (kept independent from the app target).
//

import SwiftUI

enum WidgetTheme {
    static let teal = Color(red: 0x4E / 255, green: 0xCD / 255, blue: 0xC4 / 255)
    static let tealDark = Color(red: 0x36 / 255, green: 0x9E / 255, blue: 0x97 / 255)
    static let green = Color(red: 0x3C / 255, green: 0xB3 / 255, blue: 0x71 / 255)
    static let yellow = Color(red: 0xF2 / 255, green: 0xC0 / 255, blue: 0x37 / 255)
    static let red = Color(red: 0xE5 / 255, green: 0x57 / 255, blue: 0x53 / 255)

    /// Status color from progress: green ≥1, yellow within 2h of goal, else red.
    static func statusColor(progress: Double, goalSeconds: Int) -> Color {
        if progress >= 1 { return green }
        let remaining = Double(goalSeconds) * (1 - progress)
        if remaining <= 2 * 3600 { return yellow }
        return red
    }
}
