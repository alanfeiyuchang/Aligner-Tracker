//
//  TimerViewModel.swift
//  Aligner Tracker
//
//  Drives the wear timer. The running session's start time lives in the shared
//  App Group store so it survives the app being killed; on launch/foreground we
//  reconcile elapsed time and credit it to the correct day(s), splitting any
//  interval that crosses midnight.
//

import Foundation
import Observation
import SwiftData
import WidgetKit

@MainActor
@Observable
final class TimerViewModel {
    // Observable UI state
    private(set) var isRunning = false
    private(set) var todayTotalSeconds: Double = 0
    private(set) var currentSessionSeconds: Double = 0
    /// True while the aligner is out (paused after having been worn).
    private(set) var isOff = false
    /// Live elapsed time of the current off-period, in seconds.
    private(set) var currentOffSeconds: Double = 0

    @ObservationIgnored private var context: ModelContext?
    @ObservationIgnored private var settings: AppSettings?
    @ObservationIgnored private var sessionStart: Date?
    /// When the aligner was taken out; nil unless currently off.
    @ObservationIgnored private var offStart: Date?
    @ObservationIgnored private var committedTodaySeconds: Double = 0
    /// The day `committedTodaySeconds` was loaded for. Without it the cached
    /// total silently carries into the next day.
    @ObservationIgnored private var committedDay: Date = Calendar.current.startOfDay(for: .now)
    @ObservationIgnored private var ticker: Timer?

    /// Read fresh on every use: `Calendar.current` is a snapshot, so holding one
    /// for the lifetime of the view model keeps a stale time zone after travel.
    private var cal: Calendar { Calendar.current }

    // MARK: - Wiring

    func configure(context: ModelContext, settings: AppSettings) {
        self.context = context
        self.settings = settings
        refreshFromStore()
    }

    /// Called on launch and whenever the app returns to the foreground.
    func refreshFromStore() {
        let d = SharedStore.defaults
        let running = d.bool(forKey: SharedStore.Key.isTimerRunning)

        if running, d.object(forKey: SharedStore.Key.timerStartTimestamp) != nil {
            let start = Date(timeIntervalSince1970: d.double(forKey: SharedStore.Key.timerStartTimestamp))
            // Credit any fully-elapsed days (including time while backgrounded/killed)
            // up to the start of today, then keep the remainder live.
            let startOfToday = cal.startOfDay(for: .now)
            if start < startOfToday {
                commit(from: start, to: startOfToday)
                sessionStart = startOfToday
            } else {
                sessionStart = start
            }
            isRunning = true
            offStart = nil
        } else {
            isRunning = false
            sessionStart = nil
            // Restore an in-progress off-period (survives backgrounding/kill).
            if d.object(forKey: SharedStore.Key.offStartTimestamp) != nil {
                offStart = Date(timeIntervalSince1970: d.double(forKey: SharedStore.Key.offStartTimestamp))
            } else {
                offStart = nil
            }
        }

        committedTodaySeconds = loadTodayCommitted()
        recompute()
        pushSnapshot()
        if isRunning || isOff { startTicker() }
    }

    // MARK: - Public actions

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        // Putting the aligner back in closes the current off-period.
        finalizeOffSession(endingAt: .now)
        sessionStart = .now
        isRunning = true
        committedTodaySeconds = loadTodayCommitted()
        recompute()
        pushSnapshot()
        startTicker()
        reloadWidget()
    }

    func pause() {
        guard isRunning, let start = sessionStart else { return }
        commit(from: start, to: .now)
        isRunning = false
        sessionStart = nil
        // Begin tracking how long the aligner is out.
        offStart = .now
        SharedStore.defaults.set(offStart!.timeIntervalSince1970, forKey: SharedStore.Key.offStartTimestamp)
        committedTodaySeconds = loadTodayCommitted()
        recompute()
        pushSnapshot()
        startTicker() // keep ticking to drive the live off-timer
        reloadWidget()
    }

    /// Re-push tray/goal data when settings change while paused.
    func settingsChanged() {
        committedTodaySeconds = loadTodayCommitted()
        recompute()
        pushSnapshot()
        reloadWidget()
    }

    // MARK: - Ticking

    private func startTicker() {
        stopTicker()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        let startOfToday = cal.startOfDay(for: .now)
        var dayRolled = false

        // Handle a midnight crossing while running in the foreground: close the
        // part that belongs to the day just ended and keep the rest live.
        if isRunning, let start = sessionStart, start < startOfToday {
            commit(from: start, to: startOfToday)
            sessionStart = startOfToday
            dayRolled = true
        }

        // The cached total is only valid for the day it was loaded for. This
        // also covers sitting in the foreground while paused across midnight,
        // where there is no session to roll forward.
        if committedDay != startOfToday {
            committedTodaySeconds = loadTodayCommitted()
            dayRolled = true
        }

        if dayRolled {
            pushSnapshot()
            reloadWidget()
        }
        recompute()
    }

    private func recompute() {
        if isRunning, let start = sessionStart {
            currentSessionSeconds = max(0, Date.now.timeIntervalSince(start))
        } else {
            currentSessionSeconds = 0
        }
        if !isRunning, let off = offStart {
            isOff = true
            currentOffSeconds = max(0, Date.now.timeIntervalSince(off))
        } else {
            isOff = false
            currentOffSeconds = 0
        }
        todayTotalSeconds = WearMath.wearSeconds(committedSeconds: committedTodaySeconds,
                                                 committedDay: committedDay,
                                                 isRunning: isRunning,
                                                 sessionStart: sessionStart,
                                                 at: .now,
                                                 calendar: cal)
    }

    /// Records the finished off-period as an `OffSession` and clears the
    /// in-progress off-state from both memory and the shared store.
    private func finalizeOffSession(endingAt end: Date) {
        defer {
            offStart = nil
            SharedStore.defaults.removeObject(forKey: SharedStore.Key.offStartTimestamp)
        }
        guard let context, let off = offStart, end > off else { return }
        context.insert(OffSession(startDate: off, endDate: end))
        try? context.save()
    }

    // MARK: - Persistence helpers

    private func loadTodayCommitted() -> Double {
        let today = cal.startOfDay(for: .now)
        committedDay = today
        guard let context else { return 0 }
        let desc = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.day == today })
        return (try? context.fetch(desc).first?.totalSeconds) ?? 0
    }

    private func dailyLog(for day: Date) -> DailyLog? {
        guard let context else { return nil }
        let start = cal.startOfDay(for: day)
        let desc = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.day == start })
        if let existing = try? context.fetch(desc).first { return existing }
        let log = DailyLog(day: start)
        context.insert(log)
        return log
    }

    /// Credit [from, to] to the correct daily logs, splitting at midnight.
    private func commit(from: Date, to: Date) {
        guard let context, to > from else { return }
        var segStart = from
        while segStart < to {
            let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: segStart)!)
            let segEnd = min(nextMidnight, to)
            let seconds = segEnd.timeIntervalSince(segStart)
            if seconds > 0 {
                dailyLog(for: segStart)?.totalSeconds += seconds
                context.insert(WearSession(startDate: segStart, endDate: segEnd))
            }
            segStart = segEnd
        }
        try? context.save()
    }

    // MARK: - Shared store / widget

    private func pushSnapshot() {
        guard let settings else { return }
        let snapshot = SharedStore.Snapshot(
            todayWearSeconds: Int(committedTodaySeconds),
            committedDay: committedDay,
            dailyGoalSeconds: Int(settings.dailyGoalSeconds),
            isTimerRunning: isRunning,
            timerStartTimestamp: isRunning ? sessionStart : nil,
            currentTrayNumber: settings.currentTrayNumber,
            totalTrays: settings.totalTrays,
            daysUntilChange: settings.daysUntilChange
        )
        SharedStore.write(snapshot)
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
