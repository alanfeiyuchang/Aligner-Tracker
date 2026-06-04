//
//  Aligner_TrackerApp.swift
//  Aligner Tracker
//
//  Created by ChangFeiyu on 6/2/26.
//

import SwiftUI
import SwiftData

@main
struct Aligner_TrackerApp: App {
    @State private var settings = AppSettings()
    @State private var timer = TimerViewModel()

    let container: ModelContainer = {
        let schema = Schema([DailyLog.self, WearSession.self, OffSession.self, AlignerDiaryEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(timer)
                .preferredColorScheme(colorScheme)
        }
        .modelContainer(container)
    }

    private var colorScheme: ColorScheme? {
        switch settings.colorSchemeOverride {
        case .none: return nil
        case .some(true): return .dark
        case .some(false): return .light
        }
    }
}
