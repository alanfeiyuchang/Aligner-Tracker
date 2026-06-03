//
//  NotificationService.swift
//  Aligner Tracker
//
//  Schedules and manages local notifications for aligner changes and the daily
//  wear reminder.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    private enum ID {
        static let dayBefore = "change.dayBefore"
        static let changeDay = "change.day"
        static let dailyReminder = "daily.reminder"
    }

    // MARK: Authorization

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: Scheduling

    /// Cancel and re-create all notifications according to current settings.
    func reschedule(with settings: AppSettings) async {
        center.removePendingNotificationRequests(withIdentifiers: [
            ID.dayBefore, ID.changeDay, ID.dailyReminder
        ])

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        var cal = Calendar.current
        cal.timeZone = .current
        let changeDay = cal.startOfDay(for: settings.nextChangeDate)

        // 1 day before change, at the user's chosen time.
        if settings.notifyDayBefore,
           let dayBefore = cal.date(byAdding: .day, value: -1, to: changeDay),
           let fire = cal.date(bySettingHour: settings.dayBeforeHour,
                               minute: settings.dayBeforeMinute, second: 0, of: dayBefore),
           fire > .now {
            schedule(id: ID.dayBefore,
                     title: String(localized: "Aligner reminder"),
                     body: String(localized: "Tomorrow: time to change your aligner!"),
                     at: fire)
        }

        // Change day, at the user's chosen time.
        if settings.notifyChangeDay,
           let fire = cal.date(bySettingHour: settings.changeDayHour,
                               minute: settings.changeDayMinute, second: 0, of: changeDay),
           fire > .now {
            schedule(id: ID.changeDay,
                     title: String(localized: "Aligner change day"),
                     body: String(localized: "It's aligner change day!"),
                     at: fire)
        }

        // Daily wear reminder (repeats every day at the chosen time).
        if settings.notifyDailyReminder {
            var comps = DateComponents()
            comps.hour = settings.dailyReminderHour
            comps.minute = settings.dailyReminderMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let content = makeContent(
                title: String(localized: "Don't forget your aligner"),
                body: String(localized: "Remember to wear your aligner and log today's time.")
            )
            let request = UNNotificationRequest(identifier: ID.dailyReminder,
                                                content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func schedule(id: String, title: String, body: String, at date: Date) {
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id,
                                            content: makeContent(title: title, body: body),
                                            trigger: trigger)
        center.add(request)
    }

    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
}
