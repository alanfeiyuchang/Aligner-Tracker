//
//  HistoryView.swift
//  Aligner Tracker
//
//  Calendar / log history with color coding, weekly & monthly averages and a
//  streak counter for consecutive days meeting the wear goal.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(TimerViewModel.self) private var timer
    @Query(sort: \DailyLog.day, order: .reverse) private var logs: [DailyLog]

    @State private var visibleMonth: Date = Calendar.current.startOfDay(for: .now)
    @State private var selectedDay: Date?

    private var goal: Double { settings.dailyGoalSeconds }
    private let cal = Calendar.current

    /// Today's total reflects the live timer; stored logs cover past days.
    private var totalsByDay: [Date: Double] {
        var dict: [Date: Double] = [:]
        for log in logs { dict[log.day] = log.totalSeconds }
        dict[cal.startOfDay(for: .now)] = timer.todayTotalSeconds
        return dict
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsRow
                    calendarCard
                    if let day = selectedDay {
                        selectedDayCard(day)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        let totals = totalsByDay
        return HStack(spacing: 12) {
            statCard(title: "Streak",
                     value: "\(currentStreak(totals))",
                     unit: "days",
                     icon: "flame.fill",
                     color: Theme.goalRed)
            statCard(title: "7-day avg",
                     value: WearFormatter.hm(average(totals, days: 7)),
                     unit: nil,
                     icon: "calendar",
                     color: Theme.teal)
            statCard(title: "30-day avg",
                     value: WearFormatter.hm(average(totals, days: 30)),
                     unit: nil,
                     icon: "calendar",
                     color: Theme.tealDark)
        }
    }

    private func statCard(title: LocalizedStringKey, value: String, unit: LocalizedStringKey?,
                          icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.title3.bold()).monospacedDigit()
                if let unit {
                    Text(unit).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: Calendar

    private var calendarCard: some View {
        let totals = totalsByDay
        return VStack(spacing: 14) {
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(visibleMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .tint(Theme.tealDark)

            let weekdays = cal.shortWeekdaySymbols
            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.caption2).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthCells(), id: \.self) { date in
                    if let date {
                        dayCell(date, total: totals[cal.startOfDay(for: date)])
                    } else {
                        Color.clear.frame(height: 38)
                    }
                }
            }

            legend
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func dayCell(_ date: Date, total: Double?) -> some View {
        let isToday = cal.isDateInToday(date)
        let color = total.map { cellColor(for: $0) } ?? Color(.tertiarySystemFill)
        return Button {
            selectedDay = cal.startOfDay(for: date)
        } label: {
            Text("\(cal.component(.day, from: date))")
                .font(.callout)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(Circle().fill(color).frame(width: 34, height: 34))
                .overlay {
                    if isToday {
                        Circle().stroke(Theme.tealDark, lineWidth: 2).frame(width: 34, height: 34)
                    }
                }
                .foregroundStyle(total == nil ? Color.secondary : .white)
        }
        .buttonStyle(.plain)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(Theme.goalGreen, "Met")
            legendItem(Theme.goalYellow, "Close")
            legendItem(Theme.goalRed, "Missed")
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
    }

    private func legendItem(_ color: Color, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private func selectedDayCard(_ day: Date) -> some View {
        let total = totalsByDay[day] ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            Text(day.formatted(date: .complete, time: .omitted)).font(.headline)
            HStack {
                Circle().fill(cellColor(for: total)).frame(width: 12, height: 12)
                Text(WearFormatter.hm(total))
                Text("/ \(WearFormatter.hm(goal))").foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: Helpers

    private func cellColor(for seconds: Double) -> Color {
        if seconds >= goal { return Theme.goalGreen }
        if seconds >= goal - 2 * 3600 { return Theme.goalYellow }
        return Theme.goalRed
    }

    private func changeMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = d
        }
    }

    /// Cells for the visible month, padded with nils for leading blanks.
    private func monthCells() -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstDay = interval.start
        let daysInMonth = cal.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30
        let leading = cal.component(.weekday, from: firstDay) - cal.firstWeekday
        let pad = (leading + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: pad)
        for offset in 0..<daysInMonth {
            cells.append(cal.date(byAdding: .day, value: offset, to: firstDay))
        }
        return cells
    }

    private func average(_ totals: [Date: Double], days: Int) -> Double {
        let today = cal.startOfDay(for: .now)
        var sum = 0.0
        var counted = 0
        for offset in 0..<days {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if let v = totals[d] {
                sum += v
                counted += 1
            }
        }
        return counted == 0 ? 0 : sum / Double(counted)
    }

    private func currentStreak(_ totals: [Date: Double]) -> Int {
        let today = cal.startOfDay(for: .now)
        var streak = 0
        var offset = 0
        // If today's goal isn't met yet, start counting from yesterday.
        if (totals[today] ?? 0) < goal { offset = 1 }
        while true {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { break }
            if (totals[d] ?? 0) >= goal {
                streak += 1
                offset += 1
            } else {
                break
            }
        }
        return streak
    }
}
