//
//  SharedStore.swift
//  Aligner Tracker
//
//  Read/write the App Group container shared with the widget extension.
//

import Foundation

/// Keys and accessors for the data shared between the main app and the
/// `AlignerTrackerWidget` extension via an App Group `UserDefaults` suite.
enum SharedStore {
    static let appGroupID = "group.ACM.Aligner-Tracker"

    enum Key {
        static let todayWearSeconds = "todayWearSeconds"
        static let dailyGoalSeconds = "dailyGoalSeconds"
        static let isTimerRunning = "isTimerRunning"
        static let timerStartTimestamp = "timerStartTimestamp"
        /// Midnight of the day `todayWearSeconds` was recorded for.
        static let committedDayTimestamp = "committedDayTimestamp"
        /// When the aligner was taken out (start of the current off-period).
        static let offStartTimestamp = "offStartTimestamp"
        static let currentTrayNumber = "currentTrayNumber"
        static let totalTrays = "totalTrays"
        static let daysUntilChange = "daysUntilChange"
        static let hasData = "hasData"
    }

    static let defaults: UserDefaults = {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }()

    // MARK: - Snapshot

    /// A plain value snapshot the timer view model pushes into the shared store.
    struct Snapshot {
        var todayWearSeconds: Int
        /// The day `todayWearSeconds` belongs to. The widget needs it to know
        /// whether that total still applies to the day it is rendering.
        var committedDay: Date
        var dailyGoalSeconds: Int
        var isTimerRunning: Bool
        var timerStartTimestamp: Date?
        var currentTrayNumber: Int
        var totalTrays: Int
        var daysUntilChange: Int
    }

    static func write(_ snapshot: Snapshot) {
        let d = defaults
        d.set(snapshot.todayWearSeconds, forKey: Key.todayWearSeconds)
        d.set(snapshot.committedDay.timeIntervalSince1970, forKey: Key.committedDayTimestamp)
        d.set(snapshot.dailyGoalSeconds, forKey: Key.dailyGoalSeconds)
        d.set(snapshot.isTimerRunning, forKey: Key.isTimerRunning)
        if let ts = snapshot.timerStartTimestamp {
            d.set(ts.timeIntervalSince1970, forKey: Key.timerStartTimestamp)
        } else {
            d.removeObject(forKey: Key.timerStartTimestamp)
        }
        d.set(snapshot.currentTrayNumber, forKey: Key.currentTrayNumber)
        d.set(snapshot.totalTrays, forKey: Key.totalTrays)
        d.set(snapshot.daysUntilChange, forKey: Key.daysUntilChange)
        d.set(true, forKey: Key.hasData)
    }
}
