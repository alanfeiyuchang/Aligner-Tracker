//
//  BackupService.swift
//  Aligner Tracker
//
//  Exports the user's data (settings, daily logs, diary metadata) as JSON.
//

import Foundation
import SwiftData

enum BackupService {
    struct Backup: Codable {
        struct Settings: Codable {
            var dailyGoalHours: Double
            var changeIntervalDays: Int
            var currentTrayNumber: Int
            var totalTrays: Int
            var alignerStartDate: Date
        }
        struct Day: Codable {
            var date: Date
            var totalSeconds: Double
        }
        struct Diary: Codable {
            var date: Date
            var trayNumber: Int
            var totalTreatmentDays: Int
            var note: String
            var hasPhoto: Bool
        }
        struct OffPeriod: Codable {
            var start: Date
            var end: Date
            var durationSeconds: Double
        }
        var exportedAt: Date
        var settings: Settings
        var dailyLogs: [Day]
        var diary: [Diary]
        var offPeriods: [OffPeriod]
    }

    /// Build the backup payload and write it to a temporary file for sharing.
    static func exportJSON(context: ModelContext, settings: AppSettings) throws -> URL {
        let logs = (try? context.fetch(FetchDescriptor<DailyLog>(sortBy: [SortDescriptor(\.day)]))) ?? []
        let entries = (try? context.fetch(FetchDescriptor<AlignerDiaryEntry>(sortBy: [SortDescriptor(\.date)]))) ?? []
        let offs = (try? context.fetch(FetchDescriptor<OffSession>(sortBy: [SortDescriptor(\.startDate)]))) ?? []

        let backup = Backup(
            exportedAt: .now,
            settings: .init(
                dailyGoalHours: settings.dailyGoalHours,
                changeIntervalDays: settings.changeIntervalDays,
                currentTrayNumber: settings.currentTrayNumber,
                totalTrays: settings.totalTrays,
                alignerStartDate: settings.alignerStartDate
            ),
            dailyLogs: logs.map { .init(date: $0.day, totalSeconds: $0.totalSeconds) },
            diary: entries.map {
                .init(date: $0.date, trayNumber: $0.trayNumber,
                      totalTreatmentDays: $0.totalTreatmentDays,
                      note: $0.note, hasPhoto: $0.photoData != nil)
            },
            offPeriods: offs.map {
                .init(start: $0.startDate, end: $0.endDate, durationSeconds: $0.duration)
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AlignerTracker-Backup.json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
