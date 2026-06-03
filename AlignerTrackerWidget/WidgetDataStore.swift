//
//  WidgetDataStore.swift
//  AlignerTrackerWidget
//
//  Reads the shared App Group container written by the main app.
//

import Foundation

struct WidgetData {
    var todayWearSeconds: Int
    var dailyGoalSeconds: Int
    var isTimerRunning: Bool
    var timerStartTimestamp: Date?
    var currentTrayNumber: Int
    var totalTrays: Int
    var daysUntilChange: Int
    var hasData: Bool

    /// Wear seconds projected to `date` (adds the live running session).
    func wearSeconds(at date: Date) -> Int {
        guard isTimerRunning, let start = timerStartTimestamp else { return todayWearSeconds }
        return todayWearSeconds + max(0, Int(date.timeIntervalSince(start)))
    }

    func progress(at date: Date) -> Double {
        guard dailyGoalSeconds > 0 else { return 0 }
        return Double(wearSeconds(at: date)) / Double(dailyGoalSeconds)
    }

    static let placeholder = WidgetData(
        todayWearSeconds: 18 * 3600 + 32 * 60,
        dailyGoalSeconds: 22 * 3600,
        isTimerRunning: false,
        timerStartTimestamp: nil,
        currentTrayNumber: 7,
        totalTrays: 24,
        daysUntilChange: 3,
        hasData: true
    )

    static let empty = WidgetData(
        todayWearSeconds: 0, dailyGoalSeconds: 22 * 3600,
        isTimerRunning: false, timerStartTimestamp: nil,
        currentTrayNumber: 0, totalTrays: 0, daysUntilChange: 0, hasData: false
    )
}

enum WidgetDataStore {
    static let appGroupID = "group.ACM.Aligner-Tracker"

    private enum Key {
        static let todayWearSeconds = "todayWearSeconds"
        static let dailyGoalSeconds = "dailyGoalSeconds"
        static let isTimerRunning = "isTimerRunning"
        static let timerStartTimestamp = "timerStartTimestamp"
        static let currentTrayNumber = "currentTrayNumber"
        static let totalTrays = "totalTrays"
        static let daysUntilChange = "daysUntilChange"
        static let hasData = "hasData"
    }

    static func load() -> WidgetData {
        guard let d = UserDefaults(suiteName: appGroupID), d.bool(forKey: Key.hasData) else {
            return .empty
        }
        let start: Date? = d.object(forKey: Key.timerStartTimestamp) != nil
            ? Date(timeIntervalSince1970: d.double(forKey: Key.timerStartTimestamp))
            : nil
        let goal = d.integer(forKey: Key.dailyGoalSeconds)
        return WidgetData(
            todayWearSeconds: d.integer(forKey: Key.todayWearSeconds),
            dailyGoalSeconds: goal == 0 ? 22 * 3600 : goal,
            isTimerRunning: d.bool(forKey: Key.isTimerRunning),
            timerStartTimestamp: start,
            currentTrayNumber: d.integer(forKey: Key.currentTrayNumber),
            totalTrays: d.integer(forKey: Key.totalTrays),
            daysUntilChange: d.integer(forKey: Key.daysUntilChange),
            hasData: true
        )
    }
}

enum WidgetFormat {
    static func hm(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return "\(s / 3600)h \((s % 3600) / 60)m"
    }
    /// Compact "18h32m" for the inline lock-screen widget.
    static func compact(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return "\(s / 3600)h\((s % 3600) / 60)m"
    }
}
