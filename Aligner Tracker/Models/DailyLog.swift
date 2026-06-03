//
//  DailyLog.swift
//  Aligner Tracker
//
//  Aggregated wear total for a single calendar day. `day` is normalized to the
//  start of the day so it can be used as a stable unique key.
//

import Foundation
import SwiftData

@Model
final class DailyLog {
    /// Start-of-day (local) used as the day's identity.
    @Attribute(.unique) var day: Date
    /// Total committed wear time for the day, in seconds.
    var totalSeconds: Double

    init(day: Date, totalSeconds: Double = 0) {
        self.day = Calendar.current.startOfDay(for: day)
        self.totalSeconds = totalSeconds
    }
}

extension DailyLog {
    enum GoalStatus {
        case met        // green
        case close      // yellow (within 2h of goal)
        case missed     // red
    }

    func status(goalSeconds: Double) -> GoalStatus {
        if totalSeconds >= goalSeconds { return .met }
        if totalSeconds >= goalSeconds - 2 * 3600 { return .close }
        return .missed
    }
}
