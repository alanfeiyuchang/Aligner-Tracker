//
//  AlignerTrackerWidget.swift
//  AlignerTrackerWidget
//
//  Widget configuration declaring the supported families.
//

import WidgetKit
import SwiftUI

struct AlignerTrackerWidget: Widget {
    let kind = "AlignerTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AlignerTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Aligner Tracker")
        .description("Today's wear time, tray number and days until your next change.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
