//
//  AlignerDiaryEntry.swift
//  Aligner Tracker
//
//  A photo-diary entry, normally created when the user changes to a new tray.
//

import Foundation
import SwiftData

@Model
final class AlignerDiaryEntry {
    var date: Date
    var trayNumber: Int
    /// Total days into the treatment plan at the time of the entry.
    var totalTreatmentDays: Int
    var note: String
    /// JPEG-encoded photo, stored externally to keep the store lightweight.
    @Attribute(.externalStorage) var photoData: Data?

    init(date: Date = .now,
         trayNumber: Int,
         totalTreatmentDays: Int,
         note: String = "",
         photoData: Data? = nil) {
        self.date = date
        self.trayNumber = trayNumber
        self.totalTreatmentDays = totalTreatmentDays
        self.note = note
        self.photoData = photoData
    }
}
