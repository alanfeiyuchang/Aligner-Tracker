//
//  HomeView.swift
//  Aligner Tracker
//
//  Main timer screen: big wear clock with a progress ring, plus the current
//  tray countdown and a shortcut to log an aligner change.
//

import SwiftUI

struct HomeView: View {
    @Environment(TimerViewModel.self) private var timer
    @Environment(AppSettings.self) private var settings

    @State private var showChangeFlow = false

    private var goalSeconds: Double { settings.dailyGoalSeconds }
    private var progress: Double { goalSeconds > 0 ? timer.todayTotalSeconds / goalSeconds : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    timerCard
                    trayCard
                    changeButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .sheet(isPresented: $showChangeFlow) {
                ChangeAlignerView()
            }
        }
    }

    // MARK: Timer card

    private var timerCard: some View {
        VStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 20)
                    .frame(width: 240, height: 240)

                VStack(spacing: 6) {
                    Text(WearFormatter.hm(timer.todayTotalSeconds))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("of \(WearFormatter.hm(goalSeconds)) goal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.headline)
                        .foregroundStyle(Theme.tealDark)
                }
            }
            .padding(.top, 8)

            if timer.isRunning {
                Label(WearFormatter.clock(timer.currentSessionSeconds), systemImage: "timer")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Theme.tealDark)
            } else {
                Label("Paused — aligner out", systemImage: "pause.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button(action: { timer.toggle() }) {
                Label(timer.isRunning ? "Stop (Aligner Out)" : "Start (Aligner In)",
                      systemImage: timer.isRunning ? "stop.fill" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(timer.isRunning ? Theme.goalRed : Theme.teal)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: Tray card

    private var trayCard: some View {
        let interval = max(1, settings.changeIntervalDays)
        let remaining = settings.daysUntilChange
        let elapsed = Double(interval - max(0, remaining))
        let trayProgress = min(max(elapsed / Double(interval), 0), 1)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Tray \(settings.currentTrayNumber) of \(settings.totalTrays)",
                      systemImage: "mouth")
                    .font(.headline)
                Spacer()
                Text(remainingText(remaining))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(remaining <= 1 ? Theme.goalRed : .secondary)
            }

            ProgressView(value: trayProgress)
                .tint(Theme.teal)

            Text("Next change: \(settings.nextChangeDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func remainingText(_ days: Int) -> LocalizedStringKey {
        if days < 0 { return "Overdue" }
        if days == 0 { return "Change today!" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }

    private var changeButton: some View {
        Button(action: { showChangeFlow = true }) {
            Label("Change Aligner", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(Theme.tealDark)
    }
}
