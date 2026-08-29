//
//  ChangeAlignerView.swift
//  Aligner Tracker
//
//  Flow for logging a tray change: capture a photo, add a note, confirm when
//  the change happened and which tray/treatment day it belongs to, then save a
//  diary entry and advance to the next tray. The date, time, tray number and
//  treatment day all default to the values for right now and can be adjusted,
//  which is what makes logging a change after the fact possible.
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

    @State private var changeDate = Date.now
    @State private var trayNumber = 1
    @State private var treatmentDay = 0
    /// Once the treatment day is typed by hand it stops following the date.
    @State private var treatmentDayEdited = false
    @FocusState private var noteFocused: Bool
    @FocusState private var treatmentDayFocused: Bool

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
                        .focused($noteFocused)
                }

                Section("Details") {
                    DatePicker("Date & time", selection: $changeDate)
                    Stepper(value: $trayNumber, in: 1...max(1, settings.totalTrays)) {
                        Text("Tray \(trayNumber) of \(settings.totalTrays)")
                    }
                    LabeledContent("Treatment day") {
                        TextField("Treatment day", value: treatmentDayBinding, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($treatmentDayFocused)
                    }
                    Toggle("Advance to next tray", isOn: $advanceTray)
                }
            }
            .navigationTitle("Change Aligner")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadDefaults)
            .onChange(of: changeDate) { _, newValue in
                guard !treatmentDayEdited else { return }
                treatmentDay = settings.totalTreatmentDays(asOf: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        noteFocused = false
                        treatmentDayFocused = false
                    }
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

    /// Writing straight to `treatmentDay` elsewhere keeps the "follow the date"
    /// behaviour; only a change made through this binding counts as an edit.
    private var treatmentDayBinding: Binding<Int> {
        Binding(get: { treatmentDay },
                set: { treatmentDay = max(0, $0); treatmentDayEdited = true })
    }

    /// Everything defaults to "as of right now", so the common case is one tap.
    private func loadDefaults() {
        changeDate = .now
        trayNumber = max(1, settings.currentTrayNumber)
        treatmentDay = settings.totalTreatmentDays(asOf: changeDate)
        treatmentDayEdited = false
    }

    private func save() {
        diaryVM.createEntry(context: context,
                            date: changeDate,
                            trayNumber: trayNumber,
                            totalTreatmentDays: treatmentDay,
                            image: image,
                            note: note)
        if advanceTray {
            settings.advanceToNextTray(from: trayNumber, startingAt: changeDate)
        } else if trayNumber != settings.currentTrayNumber {
            // The picker was used to correct which tray is being worn.
            settings.currentTrayNumber = trayNumber
        }
        timer.settingsChanged()
        Task { await NotificationService.shared.reschedule(with: settings) }
        dismiss()
    }
}
