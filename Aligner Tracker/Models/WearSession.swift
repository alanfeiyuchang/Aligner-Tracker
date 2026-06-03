//
//  WearSession.swift
//  Aligner Tracker
//
//  A single continuous interval during which the aligner was worn.
//  Sessions never cross midnight: a session spanning midnight is split so
//  each piece can be credited to the correct day.
//

import Foundation
import SwiftData

@Model
final class WearSession {
    var startDate: Date
    var endDate: Date

    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
}
