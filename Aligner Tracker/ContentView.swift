//
//  ContentView.swift
//  Aligner Tracker
//
//  Root view: shows onboarding on first launch, then the main tab bar.
//  Handles scene-phase refresh and widget deep links.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home, history, diary, settings
}

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(TimerViewModel.self) private var timer
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView(selectedTab: $selectedTab)
            } else {
                OnboardingView()
            }
        }
        .task {
            timer.configure(context: context, settings: settings)
            await NotificationService.shared.reschedule(with: settings)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                timer.refreshFromStore()
                Task { await NotificationService.shared.reschedule(with: settings) }
            }
        }
        .onOpenURL { url in
            switch url.host {
            case "history": selectedTab = .history
            case "diary": selectedTab = .diary
            default: selectedTab = .home
            }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "timer") }
                .tag(AppTab.home)
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(AppTab.history)
            DiaryView()
                .tabItem { Label("Diary", systemImage: "photo.on.rectangle") }
                .tag(AppTab.diary)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Theme.tealDark)
    }
}
