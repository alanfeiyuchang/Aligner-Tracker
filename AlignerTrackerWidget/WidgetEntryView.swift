//
//  WidgetEntryView.swift
//  AlignerTrackerWidget
//
//  SwiftUI views for the small / medium / lock-screen widget families.
//

import SwiftUI
import WidgetKit

private struct MiniRing: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = WidgetTheme.teal

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct AlignerTrackerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: AlignerEntry

    private var wear: Int { entry.data.wearSeconds(at: entry.date) }
    private var progress: Double { entry.data.progress(at: entry.date) }
    private var hasData: Bool { entry.data.hasData }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        case .accessoryInline: inlineView
        case .accessoryCircular: circularView
        case .accessoryRectangular: rectangularView
        default: smallView
        }
    }

    // MARK: System Small

    private var smallView: some View {
        ZStack {
            MiniRing(progress: progress, lineWidth: 11)
            VStack(spacing: 2) {
                Text(hasData ? WidgetFormat.hm(wear) : "–")
                    .font(.system(.title3, design: .rounded).bold())
                    .minimumScaleFactor(0.6)
                Text(hasData ? "/ \(WidgetFormat.hm(entry.data.dailyGoalSeconds))" : "No data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "alignertracker://home"))
    }

    // MARK: System Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            ZStack {
                MiniRing(progress: progress, lineWidth: 10)
                VStack(spacing: 1) {
                    Text(hasData ? WidgetFormat.hm(wear) : "–")
                        .font(.system(.headline, design: .rounded).bold())
                        .minimumScaleFactor(0.6)
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)

            Link(destination: URL(string: "alignertracker://history")!) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Tray \(entry.data.currentTrayNumber)", systemImage: "mouth")
                        .font(.headline)
                    Text("of \(entry.data.totalTrays)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer().frame(height: 2)
                    Text(daysText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(entry.data.daysUntilChange <= 1 ? WidgetTheme.red : WidgetTheme.tealDark)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(WidgetTheme.statusColor(progress: progress, goalSeconds: entry.data.dailyGoalSeconds))
                .frame(height: 4)
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "alignertracker://home"))
    }

    private var daysText: String {
        let d = entry.data.daysUntilChange
        if !hasData { return "–" }
        if d < 0 { return "Overdue" }
        if d == 0 { return "Change today" }
        if d == 1 { return "1 day left" }
        return "\(d) days left"
    }

    // MARK: Lock screen — inline

    private var inlineView: some View {
        Text("🦷 \(WidgetFormat.compact(wear)) · Tray \(entry.data.currentTrayNumber) · \(max(0, entry.data.daysUntilChange))d left")
    }

    // MARK: Lock screen — circular

    private var circularView: some View {
        Gauge(value: min(max(progress, 0), 1)) {
            Image(systemName: "mouth")
        } currentValueLabel: {
            Text("\(Int((progress * 100).rounded()))")
        }
        .gaugeStyle(.accessoryCircular)
    }

    // MARK: Lock screen — rectangular

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Tray \(entry.data.currentTrayNumber)/\(entry.data.totalTrays)", systemImage: "mouth")
                .font(.headline)
            Text(daysText)
                .font(.subheadline)
            Text(WidgetFormat.hm(wear))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
