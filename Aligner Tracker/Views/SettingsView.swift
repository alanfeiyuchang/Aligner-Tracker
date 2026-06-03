//
//  SettingsView.swift
//  Aligner Tracker
//
//  App settings: wear goal, aligner cycle, notifications, appearance, export.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppSettings.self) private var settingsEnv
    @Environment(\.modelContext) private var context
    @Environment(TimerViewModel.self) private var timer

    @State private var vm = SettingsViewModel()
    @State private var shareItem: ShareItem?
    @State private var exportError: String?

    var body: some View {
        @Bindable var settings = settingsEnv

        NavigationStack {
            Form {
                if vm.notificationsDenied {
                    notificationBanner
                }

                Section("Daily Wear Goal") {
                    Stepper(value: $settings.dailyGoalHours, in: 1...24, step: 0.5) {
                        Text("Goal: \(settings.dailyGoalHours, format: .number.precision(.fractionLength(1))) h")
                    }
                }

                Section("Aligner Cycle") {
                    Stepper(value: $settings.currentTrayNumber, in: 1...max(1, settings.totalTrays)) {
                        Text("Current tray: \(settings.currentTrayNumber)")
                    }
                    Stepper(value: $settings.totalTrays, in: 1...200) {
                        Text("Total trays: \(settings.totalTrays)")
                    }
                    Stepper(value: $settings.changeIntervalDays, in: 1...60) {
                        Text("Change every \(settings.changeIntervalDays) days")
                    }
                    DatePicker("Current tray start",
                               selection: $settings.alignerStartDate,
                               displayedComponents: .date)
                }

                Section("Notifications") {
                    Toggle("Day before change", isOn: $settings.notifyDayBefore)
                    if settings.notifyDayBefore {
                        DatePicker("Time",
                                   selection: timeBinding(settings,
                                                           hour: \.dayBeforeHour,
                                                           minute: \.dayBeforeMinute),
                                   displayedComponents: .hourAndMinute)
                    }

                    Toggle("On change day", isOn: $settings.notifyChangeDay)
                    if settings.notifyChangeDay {
                        DatePicker("Time",
                                   selection: timeBinding(settings,
                                                           hour: \.changeDayHour,
                                                           minute: \.changeDayMinute),
                                   displayedComponents: .hourAndMinute)
                    }

                    Toggle("Daily wear reminder", isOn: $settings.notifyDailyReminder)
                    if settings.notifyDailyReminder {
                        DatePicker("Reminder time",
                                   selection: timeBinding(settings,
                                                           hour: \.dailyReminderHour,
                                                           minute: \.dailyReminderMinute),
                                   displayedComponents: .hourAndMinute)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        Text("System").tag(Appearance.system)
                        Text("Light").tag(Appearance.light)
                        Text("Dark").tag(Appearance.dark)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Data") {
                    Button {
                        exportJSON()
                    } label: {
                        Label("Export data (JSON)", systemImage: "square.and.arrow.up")
                    }
                    if let exportError {
                        Text(exportError).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .task { await vm.refreshNotificationStatus() }
            // Reschedule notifications & refresh widget whenever relevant settings change.
            .onChange(of: settings.notifyDayBefore) { reapply() }
            .onChange(of: settings.notifyChangeDay) { reapply() }
            .onChange(of: settings.notifyDailyReminder) { reapply() }
            .onChange(of: settings.dayBeforeHour) { reapply() }
            .onChange(of: settings.dayBeforeMinute) { reapply() }
            .onChange(of: settings.changeDayHour) { reapply() }
            .onChange(of: settings.changeDayMinute) { reapply() }
            .onChange(of: settings.dailyReminderHour) { reapply() }
            .onChange(of: settings.dailyReminderMinute) { reapply() }
            .onChange(of: settings.changeIntervalDays) { reapply() }
            .onChange(of: settings.alignerStartDate) { reapply() }
            .onChange(of: settings.currentTrayNumber) { timer.settingsChanged() }
            .onChange(of: settings.totalTrays) { timer.settingsChanged() }
            .onChange(of: settings.dailyGoalHours) { timer.settingsChanged() }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url])
            }
        }
    }

    private var notificationBanner: some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.slash.fill").foregroundStyle(Theme.goalYellow)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications are off").font(.subheadline.bold())
                    Text("Enable notifications in Settings to get aligner change reminders.")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption.bold())
                }
            }
        }
    }

    /// A `Date` binding backed by separate hour/minute Int settings, so each
    /// notification can have its own independently-adjustable time.
    private func timeBinding(_ settings: AppSettings,
                             hour: ReferenceWritableKeyPath<AppSettings, Int>,
                             minute: ReferenceWritableKeyPath<AppSettings, Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: settings[keyPath: hour],
                                      minute: settings[keyPath: minute],
                                      second: 0, of: .now) ?? .now
            },
            set: { newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                settings[keyPath: hour] = comps.hour ?? 9
                settings[keyPath: minute] = comps.minute ?? 0
            }
        )
    }

    private func reapply() {
        Task { await vm.applySettings(settingsEnv) }
        timer.settingsChanged()
    }

    private func exportJSON() {
        do {
            let url = try BackupService.exportJSON(context: context, settings: settingsEnv)
            shareItem = ShareItem(url: url)
        } catch {
            exportError = error.localizedDescription
        }
    }
}
