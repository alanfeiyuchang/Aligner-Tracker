//
//  WearMathTests.swift
//  AlignerTrackerTests
//
//  Regression tests for the day-bounded wear arithmetic.
//
//  The bug these lock down: the committed total and the running session's
//  start were both carried across midnight with no record of which day the
//  committed total belonged to, so a session spanning midnight kept adding to
//  the previous day's number. The widget, which never re-derives anything and
//  only projects forward from the last snapshot, showed totals well past 24h.
//

import Foundation
import Testing

private let tz = TimeZone(identifier: "America/Los_Angeles")!

private var cal: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = tz
    return c
}

private func at(_ string: String) -> Date {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    f.timeZone = tz
    f.locale = Locale(identifier: "en_US_POSIX")
    return f.date(from: string)!
}

private func hours(_ seconds: Double) -> Double { seconds / 3600 }

@Suite("Day-bounded wear time")
struct WearMathTests {

    // MARK: The reported bug

    @Test("A session spanning midnight never reports more than the day is long")
    func sessionAcrossMidnightStaysWithinTheDay() {
        // Monday: 5h already committed, aligner back in at 13:00 and left in.
        // The snapshot is never refreshed because the app is never opened.
        let committedDay = cal.startOfDay(for: at("2026-06-01 12:00:00"))
        let sessionStart = at("2026-06-01 13:00:00")

        // Before this fix these rendered 24h, 28h, 36h and 49h.
        let cases = [
            ("2026-06-01 23:59:00", 5 + 10.9833),  // Monday: 5h committed + 10h59m live
            ("2026-06-02 00:01:00", 0.0166),       // Tuesday: only the first minute
            ("2026-06-02 08:00:00", 8.0),
            ("2026-06-02 20:00:00", 20.0),
            ("2026-06-03 09:00:00", 9.0),
        ]

        for (stamp, expected) in cases {
            let shown = WearMath.wearSeconds(committedSeconds: 5 * 3600,
                                             committedDay: committedDay,
                                             isRunning: true,
                                             sessionStart: sessionStart,
                                             at: at(stamp),
                                             calendar: cal)
            #expect(abs(hours(shown) - expected) < 0.01,
                    "at \(stamp) expected \(expected)h, got \(hours(shown))h")
            #expect(shown <= 24 * 3600)
        }
    }

    @Test("A committed total from an earlier day is not credited to today")
    func staleCommittedTotalIsDropped() {
        // Paused overnight: the aligner is out, so nothing is running and the
        // only number in hand is yesterday's committed total.
        let shown = WearMath.wearSeconds(committedSeconds: 22 * 3600,
                                         committedDay: cal.startOfDay(for: at("2026-06-01 23:00:00")),
                                         isRunning: false,
                                         sessionStart: nil,
                                         at: at("2026-06-02 07:00:00"),
                                         calendar: cal)
        #expect(shown == 0)
    }

    @Test("An unknown committed day is not credited")
    func missingCommittedDayIsDropped() {
        // A shared store last written by a build from before the fix.
        let shown = WearMath.wearSeconds(committedSeconds: 5 * 3600,
                                         committedDay: nil,
                                         isRunning: true,
                                         sessionStart: at("2026-06-01 13:00:00"),
                                         at: at("2026-06-01 15:00:00"),
                                         calendar: cal)
        #expect(hours(shown) == 2)
    }

    // MARK: Ordinary behaviour still holds

    @Test("Committed and live time add up within one day")
    func sameDayCommittedPlusLive() {
        let day = cal.startOfDay(for: at("2026-06-01 00:00:00"))
        let shown = WearMath.wearSeconds(committedSeconds: 5 * 3600,
                                         committedDay: day,
                                         isRunning: true,
                                         sessionStart: at("2026-06-01 13:00:00"),
                                         at: at("2026-06-01 16:30:00"),
                                         calendar: cal)
        #expect(hours(shown) == 8.5)
    }

    @Test("A paused day reports exactly what was committed")
    func pausedSameDay() {
        let day = cal.startOfDay(for: at("2026-06-01 00:00:00"))
        let shown = WearMath.wearSeconds(committedSeconds: 9 * 3600,
                                         committedDay: day,
                                         isRunning: false,
                                         sessionStart: at("2026-06-01 13:00:00"),
                                         at: at("2026-06-01 18:00:00"),
                                         calendar: cal)
        #expect(hours(shown) == 9)
    }

    @Test("A session that has not started yet contributes nothing")
    func futureSessionStart() {
        let day = cal.startOfDay(for: at("2026-06-01 00:00:00"))
        let shown = WearMath.wearSeconds(committedSeconds: 0,
                                         committedDay: day,
                                         isRunning: true,
                                         sessionStart: at("2026-06-01 18:00:00"),
                                         at: at("2026-06-01 17:00:00"),
                                         calendar: cal)
        #expect(shown == 0)
    }

    // MARK: Daylight saving

    @Test("The 25-hour fall-back day is bounded by its real length, not by 24h")
    func fallBackDay() {
        // 2026-11-01 in Los Angeles is 25 hours long.
        let dayStart = cal.startOfDay(for: at("2026-11-01 12:00:00"))
        let dayEnd = WearMath.nextMidnight(after: at("2026-11-01 12:00:00"), calendar: cal)
        #expect(hours(dayEnd.timeIntervalSince(dayStart)) == 25)

        let shown = WearMath.wearSeconds(committedSeconds: 0,
                                         committedDay: dayStart,
                                         isRunning: true,
                                         sessionStart: at("2026-10-31 20:00:00"),
                                         at: dayEnd.addingTimeInterval(-1),
                                         calendar: cal)
        #expect(abs(hours(shown) - 25) < 0.001)
    }

    @Test("The 23-hour spring-forward day is bounded by its real length")
    func springForwardDay() {
        let dayStart = cal.startOfDay(for: at("2026-03-08 12:00:00"))
        let dayEnd = WearMath.nextMidnight(after: at("2026-03-08 12:00:00"), calendar: cal)
        #expect(hours(dayEnd.timeIntervalSince(dayStart)) == 23)

        let shown = WearMath.wearSeconds(committedSeconds: 0,
                                         committedDay: dayStart,
                                         isRunning: true,
                                         sessionStart: at("2026-03-07 20:00:00"),
                                         at: dayEnd.addingTimeInterval(-1),
                                         calendar: cal)
        #expect(abs(hours(shown) - 23) < 0.001)
    }

    // MARK: Property

    /// The states the app can actually hand to `wearSeconds`: a committed total
    /// only ever covers the part of its day that came *before* the running
    /// session started, because everything from `sessionStart` onwards is still
    /// live and uncommitted.
    @Test("No reachable state ever reports more than the length of its day")
    func neverExceedsTheDay() {
        var rng = SeededGenerator(seed: 0x5EED_1234)
        let base = at("2026-01-01 00:00:00")

        for _ in 0..<5_000 {
            let renderAt = base.addingTimeInterval(Double.random(in: 0...(365 * 86_400), using: &rng))
            let dayStart = cal.startOfDay(for: renderAt)
            let dayLength = WearMath.nextMidnight(after: renderAt, calendar: cal)
                .timeIntervalSince(dayStart)

            let isRunning = Bool.random(using: &rng)
            let sessionStart = isRunning
                ? renderAt.addingTimeInterval(-Double.random(in: 0...(5 * 86_400), using: &rng))
                : nil

            // Pick a committed day within a few days of the render date, then a
            // committed total that could really have been recorded for it.
            let committedDay = cal.startOfDay(for: renderAt.addingTimeInterval(
                Double.random(in: -(3 * 86_400)...(3 * 86_400), using: &rng)))
            let committedCeiling: Double
            if let sessionStart, cal.isDate(committedDay, inSameDayAs: renderAt) {
                // Only the stretch before the live session can have been committed.
                committedCeiling = max(0, sessionStart.timeIntervalSince(dayStart))
            } else {
                committedCeiling = WearMath.nextMidnight(after: committedDay, calendar: cal)
                    .timeIntervalSince(committedDay)
            }
            let committed = Double.random(in: 0...max(committedCeiling, 0.001), using: &rng)

            let shown = WearMath.wearSeconds(committedSeconds: committed,
                                             committedDay: committedDay,
                                             isRunning: isRunning,
                                             sessionStart: sessionStart,
                                             at: renderAt,
                                             calendar: cal)

            #expect(shown >= 0)
            #expect(shown <= dayLength + 0.001,
                    "showed \(hours(shown))h on a \(hours(dayLength))h day")
        }
    }
}

/// Deterministic generator so a failing case can be reproduced verbatim.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
