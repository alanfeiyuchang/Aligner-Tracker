//
//  OnboardingView.swift
//  Aligner Tracker
//
//  Brief 3-screen onboarding to set total trays, current tray and interval.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settingsEnv
    @State private var page = 0

    var body: some View {
        @Bindable var settings = settingsEnv

        VStack {
            TabView(selection: $page) {
                welcomePage.tag(0)
                trayPage(settings).tag(1)
                intervalPage(settings).tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: next) {
                Text(page < 2 ? "Continue" : "Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.teal)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func next() {
        if page < 2 {
            withAnimation { page += 1 }
        } else {
            settingsEnv.hasCompletedOnboarding = true
            Task {
                await NotificationService.shared.requestAuthorization()
                await NotificationService.shared.reschedule(with: settingsEnv)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "mouth.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.teal)
            Text("Aligner Tracker")
                .font(.largeTitle.bold())
            Text("Track your wear time, manage tray changes, and keep a photo diary of your smile journey.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func trayPage(_ settings: AppSettings) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "number.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.teal)
            Text("Your trays").font(.title.bold())
            VStack(spacing: 16) {
                Stepper(value: Binding(get: { settings.totalTrays }, set: { settings.totalTrays = $0 }),
                        in: 1...200) {
                    Text("Total trays: \(settings.totalTrays)")
                }
                Stepper(value: Binding(get: { settings.currentTrayNumber },
                                       set: { settings.currentTrayNumber = $0 }),
                        in: 1...max(1, settings.totalTrays)) {
                    Text("Current tray: \(settings.currentTrayNumber)")
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func intervalPage(_ settings: AppSettings) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(Theme.teal)
            Text("Change schedule").font(.title.bold())
            VStack(spacing: 16) {
                Stepper(value: Binding(get: { settings.changeIntervalDays },
                                       set: { settings.changeIntervalDays = $0 }),
                        in: 1...60) {
                    Text("Change every \(settings.changeIntervalDays) days")
                }
                DatePicker("Current tray started",
                           selection: Binding(get: { settings.alignerStartDate },
                                              set: { settings.alignerStartDate = $0 }),
                           displayedComponents: .date)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
            .padding(.horizontal, 24)
            Spacer()
        }
    }
}
