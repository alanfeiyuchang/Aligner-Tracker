//
//  Provider.swift
//  AlignerTrackerWidget
//
//  TimelineProvider feeding all widget families from the shared App Group data.
//

import WidgetKit

struct AlignerEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AlignerEntry {
        AlignerEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AlignerEntry) -> Void) {
        let data = context.isPreview ? .placeholder : WidgetDataStore.load()
        completion(AlignerEntry(date: .now, data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AlignerEntry>) -> Void) {
        let data = WidgetDataStore.load()
        let now = Date.now
        let cal = Calendar.current

        if data.isTimerRunning {
            // Advance the displayed wear time across the next few hours so the
            // ring keeps moving; WidgetKit refreshes at most every 15 minutes.
            var entries: [AlignerEntry] = []
            for step in stride(from: 0, through: 16, by: 1) {
                let date = cal.date(byAdding: .minute, value: step * 15, to: now) ?? now
                entries.append(AlignerEntry(date: date, data: data))
            }
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            // Paused: nothing changes until the daily reset at midnight.
            let nextMidnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
            let entry = AlignerEntry(date: now, data: data)
            completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
        }
    }
}
