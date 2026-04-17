//
//  familyTabbar.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import SwiftUI

struct familyTabbar: View {
    @StateObject private var reminderViewModel = ReminderViewModel()
@EnvironmentObject var appState: AppState
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                home_family()
                    .onAppear { AnalyticsManager.shared.logScreen(name: "FamilyHome") }
            }
            Tab("Articles", systemImage: "person.2.fill") {
                NavigationStack {
                    ArticlesView()
                }
                .onAppear { AnalyticsManager.shared.logScreen(name: "FamilyArticles") }
            }
            Tab("Journal", systemImage: "book.fill") {
                NavigationStack {
                    JournalView()
                }
                .onAppear { AnalyticsManager.shared.logScreen(name: "FamilyJournal") }
            }
            Tab("Smriti", systemImage: "apple.intelligence", role: .search) {
                SmritiSearchTab()
                .environmentObject(appState)
                    .onAppear { AnalyticsManager.shared.logScreen(name: "FamilySmriti") }
            }
//            Tab("Reminders", systemImage: "bell.badge.waveform.fill") {
//                NavigationStack {
//                    remindersView(viewModel: reminderViewModel)
//                }
//            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppConfig.Colors.accent)
        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
    }
}

#Preview {
    familyTabbar()
}
