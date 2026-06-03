//
//  ChangeAlignerView.swift
//  Aligner Tracker
//
//  Flow for logging a tray change: capture a photo, add a note, auto-stamp
//  metadata, save a diary entry and advance to the next tray.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ChangeAlignerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(TimerViewModel.self) private var timer

    @State private var diaryVM = DiaryViewModel()
    @State private var image: UIImage?
    @State private var note: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var advanceTray = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    photoArea
                    HStack {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera.fill")
                        }
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        Spacer()
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("Choose", systemImage: "photo.on.rectangle")
                        }
                    }
                    .font(.subheadline)
                }

                Section("Note") {
                    TextField("e.g. Tray 8 — teeth feel tighter", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Details") {
                    LabeledContent("Date", value: Date.now.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Tray", value: "\(settings.currentTrayNumber) of \(settings.totalTrays)")
                    LabeledContent("Treatment day", value: "\(settings.totalTreatmentDays)")
                    Toggle("Advance to next tray", isOn: $advanceTray)
                }
            }
            .navigationTitle("Change Aligner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { captured in image = captured }
                    .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        image = ui
                    }
                }
            }
        }
    }

    private var photoArea: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.teal.opacity(0.12))
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.largeTitle)
                                .foregroundStyle(Theme.tealDark)
                            Text("Add a smile photo")
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    private func save() {
        diaryVM.createEntry(context: context, settings: settings, image: image, note: note)
        if advanceTray {
            settings.advanceToNextTray()
        }
        timer.settingsChanged()
        Task { await NotificationService.shared.reschedule(with: settings) }
        dismiss()
    }
}
