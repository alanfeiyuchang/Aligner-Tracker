//
//  WearMath.swift
//  Aligner Tracker
//
//  Day-bounded wear arithmetic, shared by the app and the widget extension.
//
//  Both sides hold the same two pieces of state: a committed total for one
//  calendar day, and the start of a session that may still be running. Neither
//  piece is meaningful without knowing which day the committed total belongs
//  to, which is why `committedDay` is required here — a running session that
//  crosses midnight otherwise keeps piling onto the previous day's total.
//

import Foundation

enum WearMath {

    /// Wear seconds to show for the calendar day that contains `date`.
    ///
    /// - `committedSeconds` counts only when `committedDay` is that same day.
    /// - A running session counts only from the later of its own start and
    ///   that day's midnight, so the portion belonging to earlier days is left
    ///   for those days.
    ///
    /// Nothing is clamped: for well-formed inputs the result cannot exceed the
    /// length of the day, so a larger value means an input is wrong and should
    /// be visible rather than hidden.
    static func wearSeconds(committedSeconds: Double,
                            committedDay: Date?,
                            isRunning: Bool,
                            sessionStart: Date?,
                            at date: Date,
                            calendar: Calendar) -> Double {
        var total: Double = 0

        if let committedDay, calendar.isDate(committedDay, inSameDayAs: date) {
            total += max(0, committedSeconds)
        }

        if isRunning, let sessionStart {
            let dayStart = calendar.startOfDay(for: date)
            total += max(0, date.timeIntervalSince(max(sessionStart, dayStart)))
        }

        return total
    }

    /// Midnight at the end of the day containing `date`.
    static func nextMidnight(after date: Date, calendar: Calendar) -> Date {
        let next = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86_400)
        return calendar.startOfDay(for: next)
    }
}
