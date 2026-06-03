//
//  DiaryEntryView.swift
//  Aligner Tracker
//
//  Full-screen detail for a single diary entry with all metadata and sharing.
//

import SwiftUI
import SwiftData

struct DiaryEntryView: View {
    let entry: AlignerDiaryEntry

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var diaryVM = DiaryViewModel()
    @State private var shareItem: ShareItem?
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data = entry.photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.teal.opacity(0.12))
                        .frame(height: 240)
                        .overlay(Image(systemName: "mouth").font(.system(size: 48)).foregroundStyle(Theme.tealDark))
                }

                VStack(alignment: .leading, spacing: 10) {
                    metaRow("mouth", "Tray", "\(entry.trayNumber)")
                    metaRow("calendar", "Date", entry.date.formatted(date: .complete, time: .shortened))
                    metaRow("clock", "Treatment day", "\(entry.totalTreatmentDays)")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))

                if !entry.note.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note").font(.headline)
                        Text(entry.note).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tray \(entry.trayNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if let url = diaryVM.exportPDF(entries: [entry], fileName: "Tray-\(entry.trayNumber)") {
                            shareItem = ShareItem(url: url)
                        }
                    } label: {
                        Label("Share as PDF", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $shareItem) { item in ShareSheet(items: [item.url]) }
        .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                diaryVM.delete(entry, context: context)
                dismiss()
            }
        }
    }

    private func metaRow(_ icon: String, _ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Label(label, systemImage: icon).foregroundStyle(Theme.tealDark)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
