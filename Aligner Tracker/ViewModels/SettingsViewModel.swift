//
//  SettingsViewModel.swift
//  Aligner Tracker
//
//  Coordinates settings changes with notification scheduling and data export.
//

import Foundation
import Observation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class SettingsViewModel {
    var notificationStatus: UNAuthorizationStatus = .notDetermined

    func refreshNotificationStatus() async {
        notificationStatus = await NotificationService.shared.authorizationStatus()
    }

    func requestNotifications(settings: AppSettings) async {
        _ = await NotificationService.shared.requestAuthorization()
        await refreshNotificationStatus()
        await NotificationService.shared.reschedule(with: settings)
    }

    func applySettings(_ settings: AppSettings) async {
        await NotificationService.shared.reschedule(with: settings)
    }

    /// Whether notifications were explicitly denied (used to show the banner).
    var notificationsDenied: Bool { notificationStatus == .denied }
}
