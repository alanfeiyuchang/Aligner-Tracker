//
//  DiaryViewModel.swift
//  Aligner Tracker
//
//  Manages diary entries: creation, deletion and PDF export.
//

import Foundation
import Observation
import SwiftData
import UIKit

@MainActor
@Observable
final class DiaryViewModel {

    @discardableResult
    func createEntry(context: ModelContext,
                     settings: AppSettings,
                     image: UIImage?,
                     note: String) -> AlignerDiaryEntry {
        let data = image?.jpegData(compressionQuality: 0.8)
        let entry = AlignerDiaryEntry(
            date: .now,
            trayNumber: settings.currentTrayNumber,
            totalTreatmentDays: settings.totalTreatmentDays,
            note: note,
            photoData: data
        )
        context.insert(entry)
        try? context.save()
        return entry
    }

    func delete(_ entry: AlignerDiaryEntry, context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }

    // MARK: - PDF export

    private let pageSize = CGSize(width: 612, height: 792) // US Letter @72dpi

    func exportPDF(entries: [AlignerDiaryEntry], fileName: String = "AlignerDiary") -> URL? {
        guard !entries.isEmpty else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        do {
            try renderer.writePDF(to: url) { ctx in
                for entry in entries {
                    ctx.beginPage()
                    draw(entry: entry, in: ctx.pdfContextBounds)
                }
            }
            return url
        } catch {
            return nil
        }
    }

    private func draw(entry: AlignerDiaryEntry, in bounds: CGRect) {
        let margin: CGFloat = 40
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15)
        ]

        let df = DateFormatter()
        df.dateStyle = .long

        var y = margin
        ("Tray \(entry.trayNumber)" as NSString)
            .draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr)
        y += 40

        let meta = """
        Date: \(df.string(from: entry.date))
        Day \(entry.totalTreatmentDays) of treatment
        """
        (meta as NSString).draw(in: CGRect(x: margin, y: y, width: bounds.width - 2 * margin, height: 60),
                                withAttributes: bodyAttr)
        y += 70

        if let data = entry.photoData, let image = UIImage(data: data) {
            let maxW = bounds.width - 2 * margin
            let maxH: CGFloat = 380
            let ratio = min(maxW / image.size.width, maxH / image.size.height)
            let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            image.draw(in: CGRect(x: margin, y: y, width: size.width, height: size.height))
            y += size.height + 20
        }

        if !entry.note.isEmpty {
            (entry.note as NSString).draw(
                in: CGRect(x: margin, y: y, width: bounds.width - 2 * margin, height: bounds.height - y - margin),
                withAttributes: bodyAttr)
        }
    }
}
