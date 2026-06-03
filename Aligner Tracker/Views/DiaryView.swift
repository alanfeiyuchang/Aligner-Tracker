//
//  DiaryView.swift
//  Aligner Tracker
//
//  Photo-diary gallery shown as a timeline grid of entries.
//

import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \AlignerDiaryEntry.date, order: .reverse) private var entries: [AlignerDiaryEntry]

    @State private var diaryVM = DiaryViewModel()
    @State private var shareItem: ShareItem?
    @State private var showChangeFlow = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(entries) { entry in
                                NavigationLink {
                                    DiaryEntryView(entry: entry)
                                } label: {
                                    DiaryThumbnail(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Diary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showChangeFlow = true } label: {
                        Image(systemName: "plus")
                    }
                }
                if !entries.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            if let url = diaryVM.exportPDF(entries: entries) {
                                shareItem = ShareItem(url: url)
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showChangeFlow) { ChangeAlignerView() }
            .sheet(item: $shareItem) { item in ShareSheet(items: [item.url]) }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No diary entries", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Tap + or use “Change Aligner” to add your first entry.")
        }
    }
}

struct DiaryThumbnail: View {
    let entry: AlignerDiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let data = entry.photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.teal.opacity(0.12)
                        .overlay(Image(systemName: "mouth").font(.largeTitle).foregroundStyle(Theme.tealDark))
                }
            }
            .frame(height: 150)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text("Tray \(entry.trayNumber)").font(.subheadline.bold())
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
                if !entry.note.isEmpty {
                    Text(entry.note).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemGroupedBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
