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

    @ObservationIgnored private var context: ModelContext?
    @ObservationIgnored private var settings: AppSettings?
    @ObservationIgnored private var sessionStart: Date?
    @ObservationIgnored private var committedTodaySeconds: Double = 0
    @ObservationIgnored private var ticker: Timer?

    private let cal = Calendar.current

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
        } else {
            isRunning = false
            sessionStart = nil
        }

        committedTodaySeconds = loadTodayCommitted()
        recompute()
        pushSnapshot()
        if isRunning { startTicker() }
    }

    // MARK: - Public actions

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
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
        stopTicker()
        committedTodaySeconds = loadTodayCommitted()
        recompute()
        pushSnapshot()
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
        guard isRunning, let start = sessionStart else { return }
        // Handle a midnight crossing while running in the foreground.
        let startOfToday = cal.startOfDay(for: .now)
        if start < startOfToday {
            commit(from: start, to: startOfToday)
            sessionStart = startOfToday
            committedTodaySeconds = loadTodayCommitted()
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
        todayTotalSeconds = committedTodaySeconds + currentSessionSeconds
    }

    // MARK: - Persistence helpers

    private func loadTodayCommitted() -> Double {
        guard let context else { return 0 }
        let today = cal.startOfDay(for: .now)
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
