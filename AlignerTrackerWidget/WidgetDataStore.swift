//
//  WidgetDataStore.swift
//  AlignerTrackerWidget
//
//  Reads the shared App Group container written by the main app.
//

import Foundation

struct WidgetData {
    var todayWearSeconds: Int
    /// Midnight of the day `todayWearSeconds` was recorded for. Without it a
    /// running session that crosses midnight keeps adding to the previous
    /// day's total, which is how the widget used to show more than 24h.
    var committedDay: Date?
    var dailyGoalSeconds: Int
    var isTimerRunning: Bool
    var timerStartTimestamp: Date?
    var currentTrayNumber: Int
    var totalTrays: Int
    var daysUntilChange: Int
    var hasData: Bool

    /// Wear seconds for the calendar day containing `date`, projected to `date`.
    func wearSeconds(at date: Date) -> Int {
        Int(WearMath.wearSeconds(committedSeconds: Double(todayWearSeconds),
                                 committedDay: committedDay,
                                 isRunning: isTimerRunning,
                                 sessionStart: timerStartTimestamp,
                                 at: date,
                                 calendar: .current))
    }

    func progress(at date: Date) -> Double {
        guard dailyGoalSeconds > 0 else { return 0 }
        return Double(wearSeconds(at: date)) / Double(dailyGoalSeconds)
    }

    static let placeholder = WidgetData(
        todayWearSeconds: 18 * 3600 + 32 * 60,
        committedDay: Calendar.current.startOfDay(for: .now),
        dailyGoalSeconds: 22 * 3600,
        isTimerRunning: false,
        timerStartTimestamp: nil,
        currentTrayNumber: 7,
        totalTrays: 24,
        daysUntilChange: 3,
        hasData: true
    )

    static let empty = WidgetData(
        todayWearSeconds: 0, committedDay: nil, dailyGoalSeconds: 22 * 3600,
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
        static let committedDayTimestamp = "committedDayTimestamp"
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
        // Written since the day-bounded fix; absent on a store last written by
        // an older build, in which case the committed total is dropped rather
        // than credited to the wrong day. The next app launch restores it.
        let committedDay: Date? = d.object(forKey: Key.committedDayTimestamp) != nil
            ? Date(timeIntervalSince1970: d.double(forKey: Key.committedDayTimestamp))
            : nil
        let goal = d.integer(forKey: Key.dailyGoalSeconds)
        return WidgetData(
            todayWearSeconds: d.integer(forKey: Key.todayWearSeconds),
            committedDay: committedDay,
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
