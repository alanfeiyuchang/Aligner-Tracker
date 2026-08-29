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
        let midnight = WearMath.nextMidnight(after: now, calendar: cal)

        var entries: [AlignerEntry] = []
        if data.isTimerRunning {
            // Advance the displayed wear time across the next few hours so the
            // ring keeps moving; WidgetKit refreshes at most every 15 minutes.
            for step in stride(from: 0, through: 16, by: 1) {
                guard let date = cal.date(byAdding: .minute, value: step * 15, to: now),
                      date < midnight else { break }
                entries.append(AlignerEntry(date: date, data: data))
            }
        }
        if entries.isEmpty { entries.append(AlignerEntry(date: now, data: data)) }

        // Land an entry exactly on midnight when it falls inside the window, so
        // the day resets on the boundary even if the app is never opened and no
        // fresh snapshot is pushed. `wearSeconds(at:)` is day-bounded, so that
        // entry renders the new day on its own.
        if midnight <= now.addingTimeInterval(4 * 3600) {
            entries.append(AlignerEntry(date: midnight, data: data))
        }

        // Paused, nothing moves until the day flips; running, reload at the end
        // of the window or at midnight, whichever comes first.
        let windowEnd = entries.last?.date ?? now
        let reload = data.isTimerRunning ? min(midnight, windowEnd) : midnight
        completion(Timeline(entries: entries, policy: .after(reload)))
    }
}
