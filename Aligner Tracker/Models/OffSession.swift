//
//  OffSession.swift
//  Aligner Tracker
//
//  A single continuous interval during which the aligner was taken OUT
//  (not worn). Recorded when the user resumes wearing, so each entry has a
//  definite start, end and total duration that the History screen lists.
//

import Foundation
import SwiftData

@Model
final class OffSession {
    /// When the aligner was taken out.
    var startDate: Date
    /// When the aligner was put back in.
    var endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    /// Total time the aligner was out, in seconds.
    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
}
