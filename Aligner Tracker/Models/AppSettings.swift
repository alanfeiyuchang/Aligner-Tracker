//
//  AppSettings.swift
//  Aligner Tracker
//
//  Observable user settings, persisted to the App Group UserDefaults so the
//  widget can read the same values. Acts as the model behind SettingsViewModel.
//

import Foundation
import Observation

enum Appearance: Int, CaseIterable, Identifiable {
    case system = 0, light, dark
    var id: Int { rawValue }
}

@Observable
final class AppSettings {
    private let defaults = SharedStore.defaults

    // MARK: Stored keys
    private enum K {
        static let dailyGoalHours = "set.dailyGoalHours"
        static let changeIntervalDays = "set.changeIntervalDays"
        static let currentTrayNumber = "set.currentTrayNumber"
        static let totalTrays = "set.totalTrays"
        static let alignerStartDate = "set.alignerStartDate"
        static let notifyDayBefore = "set.notifyDayBefore"
        static let notifyChangeDay = "set.notifyChangeDay"
        static let notifyDailyReminder = "set.notifyDailyReminder"
        static let dayBeforeHour = "set.dayBeforeHour"
        static let dayBeforeMinute = "set.dayBeforeMinute"
        static let changeDayHour = "set.changeDayHour"
        static let changeDayMinute = "set.changeDayMinute"
        static let dailyReminderHour = "set.dailyReminderHour"
        static let dailyReminderMinute = "set.dailyReminderMinute"
        static let appearance = "set.appearance"
        static let hasOnboarded = "set.hasOnboarded"
    }

    // MARK: Observable properties (each persists on write)

    var dailyGoalHours: Double {
        didSet { defaults.set(dailyGoalHours, forKey: K.dailyGoalHours) }
    }
    var changeIntervalDays: Int {
        didSet { defaults.set(changeIntervalDays, forKey: K.changeIntervalDays) }
    }
    var currentTrayNumber: Int {
        didSet { defaults.set(currentTrayNumber, forKey: K.currentTrayNumber) }
    }
    var totalTrays: Int {
        didSet { defaults.set(totalTrays, forKey: K.totalTrays) }
    }
    var alignerStartDate: Date {
        didSet { defaults.set(alignerStartDate.timeIntervalSince1970, forKey: K.alignerStartDate) }
    }
    var notifyDayBefore: Bool {
        didSet { defaults.set(notifyDayBefore, forKey: K.notifyDayBefore) }
    }
    var notifyChangeDay: Bool {
        didSet { defaults.set(notifyChangeDay, forKey: K.notifyChangeDay) }
    }
    var notifyDailyReminder: Bool {
        didSet { defaults.set(notifyDailyReminder, forKey: K.notifyDailyReminder) }
    }
    var dayBeforeHour: Int {
        didSet { defaults.set(dayBeforeHour, forKey: K.dayBeforeHour) }
    }
    var dayBeforeMinute: Int {
        didSet { defaults.set(dayBeforeMinute, forKey: K.dayBeforeMinute) }
    }
    var changeDayHour: Int {
        didSet { defaults.set(changeDayHour, forKey: K.changeDayHour) }
    }
    var changeDayMinute: Int {
        didSet { defaults.set(changeDayMinute, forKey: K.changeDayMinute) }
    }
    var dailyReminderHour: Int {
        didSet { defaults.set(dailyReminderHour, forKey: K.dailyReminderHour) }
    }
    var dailyReminderMinute: Int {
        didSet { defaults.set(dailyReminderMinute, forKey: K.dailyReminderMinute) }
    }
    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: K.appearance) }
    }
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: K.hasOnboarded) }
    }

    init() {
        let d = SharedStore.defaults
        // Register sensible defaults (daily goal of 22h, 10-day interval).
        d.register(defaults: [
            K.dailyGoalHours: 22.0,
            K.changeIntervalDays: 10,
            K.currentTrayNumber: 1,
            K.totalTrays: 24,
            K.alignerStartDate: Date.now.timeIntervalSince1970,
            K.notifyDayBefore: true,
            K.notifyChangeDay: true,
            K.notifyDailyReminder: false,
            K.dayBeforeHour: 9,
            K.dayBeforeMinute: 0,
            K.changeDayHour: 9,
            K.changeDayMinute: 0,
            K.dailyReminderHour: 9,
            K.dailyReminderMinute: 0,
            K.appearance: Appearance.system.rawValue,
            K.hasOnboarded: false
        ])

        dailyGoalHours = d.double(forKey: K.dailyGoalHours)
        changeIntervalDays = d.integer(forKey: K.changeIntervalDays)
        currentTrayNumber = d.integer(forKey: K.currentTrayNumber)
        totalTrays = d.integer(forKey: K.totalTrays)
        alignerStartDate = Date(timeIntervalSince1970: d.double(forKey: K.alignerStartDate))
        notifyDayBefore = d.bool(forKey: K.notifyDayBefore)
        notifyChangeDay = d.bool(forKey: K.notifyChangeDay)
        notifyDailyReminder = d.bool(forKey: K.notifyDailyReminder)
        dayBeforeHour = d.integer(forKey: K.dayBeforeHour)
        dayBeforeMinute = d.integer(forKey: K.dayBeforeMinute)
        changeDayHour = d.integer(forKey: K.changeDayHour)
        changeDayMinute = d.integer(forKey: K.changeDayMinute)
        dailyReminderHour = d.integer(forKey: K.dailyReminderHour)
        dailyReminderMinute = d.integer(forKey: K.dailyReminderMinute)
        appearance = Appearance(rawValue: d.integer(forKey: K.appearance)) ?? .system
        hasCompletedOnboarding = d.bool(forKey: K.hasOnboarded)
    }

    // MARK: Derived values

    var dailyGoalSeconds: Double { dailyGoalHours * 3600 }

    /// The date the current tray is due to be replaced.
    var nextChangeDate: Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: alignerStartDate)
        return cal.date(byAdding: .day, value: changeIntervalDays, to: start) ?? start
    }

    /// Whole days remaining until the next change (0 = due today, may be negative if overdue).
    var daysUntilChange: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let due = cal.startOfDay(for: nextChangeDate)
        return cal.dateComponents([.day], from: today, to: due).day ?? 0
    }

    /// Total days into the overall treatment plan as of today.
    var totalTreatmentDays: Int {
        let cal = Calendar.current
        let firstTrayStart = cal.date(byAdding: .day,
                                      value: -(currentTrayNumber - 1) * changeIntervalDays,
                                      to: cal.startOfDay(for: alignerStartDate)) ?? alignerStartDate
        let days = cal.dateComponents([.day], from: firstTrayStart, to: cal.startOfDay(for: .now)).day ?? 0
        return max(0, days)
    }

    var colorSchemeOverride: Bool? {
        switch appearance {
        case .system: return nil
        case .light: return false
        case .dark: return true
        }
    }

    /// Advance to the next tray, resetting the cycle start to today.
    func advanceToNextTray() {
        currentTrayNumber = min(currentTrayNumber + 1, max(totalTrays, currentTrayNumber + 1))
        alignerStartDate = .now
    }
}
