//
//  patientTabbar.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct patientTabbar: View {
    @StateObject private var reminderViewModel = ReminderViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                home()
            }
            Tab("Family", systemImage: "person.2.fill") {
                familyView()
            }
            Tab("Games", systemImage: "gamecontroller.fill") {
                games()
            }
            Tab("Smriti", systemImage: "apple.intelligence") {
                SmritiView()
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
        .onAppear {
            // Request permissions on launch
            NotificationManager.shared.requestAuthorization()

            // Fetch reminders to schedule them
            let patientId =
                KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?
                .id ?? ""
            if !patientId.isEmpty {
                Task {
                    await reminderViewModel.fetchReminders(patientId: patientId)
                }
            }
        }
        .onChange(of: reminderViewModel.reminders) { reminders in
            scheduleNotifications(for: reminders)
        }
    }

    private func scheduleNotifications(for reminders: [Reminder]) {
        let manager = NotificationManager.shared
        // Clear existing to avoid duplicates/stale data
        manager.removeAllReminderNotifications {
            // Schedule new ones only after removal is complete
            for reminder in reminders {
                let frequency = reminder.frequency

                // Generate notification content
                // Using logic from frequencies
                if let (componentsList, repeats) = frequency.calendarDateComponents(
                    for: reminder.time, calendar: NotificationManager.istCalendar)
                {
                    for components in componentsList {
                        manager.schedule(
                            on: components,
                            title: reminder.title,
                            body: reminder.notes
                                ?? "It's time for your \(reminder.category.rawValue) reminder!",
                            repeats: repeats,
                            categoryIdentifier: "reminder",
                            sound: .default
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    patientTabbar()
}
