//
//  ScreenshotSeed.swift
//  Aligner Tracker
//
//  DEBUG-only: fills the app with a fixed, good-looking data set so every
//  screen can be photographed the same way on every device. Nothing here is
//  compiled into a Release build.
//
//  Launch with `SIMCTL_CHILD_ALIGNER_SHOT=<mode>`:
//    home | history | diary | settings   open on that tab
//    change                              Home with the Change Aligner sheet up
//    entry                               Diary, pushed into the newest entry
//    onboarding | onboarding2 | onboarding3   first-launch flow, page 1–3
//  Add `SIMCTL_CHILD_ALIGNER_SHOT_RUNNING=1` to show the timer running.
//  See docs/iphone-duo.md for the full screenshot loop.
//

#if DEBUG
import SwiftUI
import SwiftData
import UIKit

enum ScreenshotSeed {
    static let mode: String? = ProcessInfo.processInfo.environment["ALIGNER_SHOT"]

    static var initialTab: AppTab {
        switch mode {
        case "history": return .history
        case "diary", "entry": return .diary
        case "settings": return .settings
        default: return .home
        }
    }

    static var isOnboarding: Bool { mode?.hasPrefix("onboarding") == true }

    static var onboardingPage: Int {
        switch mode {
        case "onboarding2": return 1
        case "onboarding3": return 2
        default: return 0
        }
    }

    /// Replaces whatever is stored with the demo data set. Runs on every
    /// seeded launch, so two launches on the same day render identically.
    @MainActor
    static func apply(settings: AppSettings, container: ModelContainer) {
        guard let mode else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let context = container.mainContext

        try? context.delete(model: DailyLog.self)
        try? context.delete(model: WearSession.self)
        try? context.delete(model: OffSession.self)
        try? context.delete(model: AlignerDiaryEntry.self)

        settings.hasCompletedOnboarding = !isOnboarding
        settings.dailyGoalHours = 22
        settings.totalTrays = 24
        settings.currentTrayNumber = 7
        settings.changeIntervalDays = 10
        settings.alignerStartDate = cal.date(byAdding: .day, value: -7, to: today) ?? today
        settings.appearance = .system

        // Today sits just under the goal; the past two months are mostly green
        // with a few yellow and red days so the calendar shows all three.
        context.insert(DailyLog(day: today, totalSeconds: 21 * 3600 + 3 * 60))
        for offset in 1...60 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let hours: Double
            switch offset % 11 {
            case 4: hours = 20.6
            case 9: hours = 18.2
            default: hours = 22.1 + Double(offset % 5) * 0.2
            }
            context.insert(DailyLog(day: day, totalSeconds: hours * 3600))
        }

        func at(_ hour: Int, _ minute: Int) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: today) ?? today
        }
        context.insert(OffSession(startDate: at(7, 10), endDate: at(7, 34)))
        context.insert(OffSession(startDate: at(12, 5), endDate: at(12, 41)))

        let notes = ["Gaps are closing", "Front teeth lining up", "Tight for two days", "Fits well", "", "First tray!"]
        for (index, note) in notes.enumerated() {
            let tray = 6 - index
            let day = cal.date(byAdding: .day, value: -7 - index * 10, to: at(8, 30)) ?? today
            context.insert(AlignerDiaryEntry(date: day,
                                             trayNumber: tray,
                                             totalTreatmentDays: (tray - 1) * 10,
                                             note: note,
                                             photoData: smilePhoto(step: index).jpegData(compressionQuality: 0.9)))
        }
        try? context.save()

        let d = SharedStore.defaults
        d.removeObject(forKey: SharedStore.Key.offStartTimestamp)
        if ProcessInfo.processInfo.environment["ALIGNER_SHOT_RUNNING"] != nil {
            d.set(true, forKey: SharedStore.Key.isTimerRunning)
            d.set(Date.now.timeIntervalSince1970, forKey: SharedStore.Key.timerStartTimestamp)
        } else {
            d.set(false, forKey: SharedStore.Key.isTimerRunning)
            d.removeObject(forKey: SharedStore.Key.timerStartTimestamp)
        }
    }

    /// A drawn stand-in for a smile photo: a soft backdrop and a row of teeth.
    private static func smilePhoto(step: Int) -> UIImage {
        let size = CGSize(width: 900, height: 900)
        let hue = 0.47 + CGFloat(step) * 0.035
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let colors = [UIColor(hue: hue, saturation: 0.30, brightness: 0.96, alpha: 1).cgColor,
                          UIColor(hue: hue + 0.06, saturation: 0.55, brightness: 0.78, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            let mouth = UIBezierPath()
            mouth.move(to: CGPoint(x: 170, y: 400))
            mouth.addQuadCurve(to: CGPoint(x: 730, y: 400), controlPoint: CGPoint(x: 450, y: 330))
            mouth.addQuadCurve(to: CGPoint(x: 170, y: 400), controlPoint: CGPoint(x: 450, y: 760))
            mouth.close()
            UIColor(red: 0.62, green: 0.22, blue: 0.25, alpha: 1).setFill()
            mouth.fill()

            cg.saveGState()
            mouth.addClip()
            UIColor.white.setFill()
            for tooth in 0..<8 {
                let rect = CGRect(x: 178 + CGFloat(tooth) * 69, y: 330, width: 62, height: 150)
                UIBezierPath(roundedRect: rect, cornerRadius: 22).fill()
            }
            cg.restoreGState()
        }
    }
}
#endif
