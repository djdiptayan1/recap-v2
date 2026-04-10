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
            Tab("Today", systemImage: "house.fill") {
                home()
                    .onAppear { AnalyticsManager.shared.logScreen(name: "PatientHome") }
            }

            Tab("Journal", systemImage: "book.fill") {
                NavigationStack {
                    JournalView()
                }
                .onAppear { AnalyticsManager.shared.logScreen(name: "PatientJournal") }
            }

            Tab("Games", systemImage: "gamecontroller.fill") {
                games()
                    .onAppear { AnalyticsManager.shared.logScreen(name: "PatientGames") }
            }

            Tab("Smriti", systemImage: "apple.intelligence", role: .search) {
                SmritiSearchTab()
                    .environmentObject(appState)
                    .onAppear { AnalyticsManager.shared.logScreen(name: "PatientSmriti") }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(AppConfig.Colors.accent)
        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        .onAppear {
            NotificationManager.shared.requestAuthorization()

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
        manager.removeAllReminderNotifications {
            for reminder in reminders {
                let frequency = reminder.frequency
                let subtitle = Self.buildNotificationSubtitle(for: reminder)
                let body = Self.buildNotificationBody(for: reminder)
                var userInfo: [AnyHashable: Any] = [
                    "reminderId": reminder.id,
                    "reminderTitle": reminder.title,
                    "reminderCategory": reminder.category.rawValue,
                ]
                if let details = reminder.categoryDetails {
                    for (key, value) in details {
                        userInfo["detail_\(key)"] = value
                    }
                }

                if let (componentsList, repeats) = frequency.calendarDateComponents(
                    for: reminder.time, calendar: NotificationManager.istCalendar) {
                    for components in componentsList {
                        manager.schedule(
                            on: components,
                            title: reminder.title,
                            body: body,
                            subtitle: subtitle,
                            repeats: repeats,
                            categoryIdentifier: "reminder",
                            userInfo: userInfo,
                            sound: .default
                        )
                    }
                }
            }
        }
    }

    private static func buildNotificationSubtitle(for reminder: Reminder) -> String {
        let timeString = reminder.time.formatted(date: .omitted, time: .shortened)
        return "\(reminder.category.rawValue) · \(timeString) · \(reminder.frequency.displayName)"
    }

    private static func buildNotificationBody(for reminder: Reminder) -> String {
        var lines: [String] = []

        if let details = reminder.categoryDetails, !details.isEmpty {
            var handledKeys: Set<String> = []
            let fields = reminder.category.detailFields

            for field in fields {
                guard !handledKeys.contains(field.key) else { continue }
                guard let value = details[field.key], !value.isEmpty else { continue }

                let unitField = fields.first {
                    $0.key == "\(field.key)Unit" || ($0.key == "unit" && field.key == "amount")
                }
                if let unitField, let unitValue = details[unitField.key], !unitValue.isEmpty {
                    lines.append("\(field.label): \(value) \(unitValue)")
                    handledKeys.insert(unitField.key)
                } else if field.key.hasSuffix("Unit") || field.key == "unit" {
                    continue
                } else {
                    lines.append("\(field.label): \(value)")
                }
                handledKeys.insert(field.key)
            }
        }

        if let notes = reminder.notes, !notes.isEmpty {
            lines.append(notes)
        }

        if lines.isEmpty {
            return "It's time for your \(reminder.category.rawValue) reminder!"
        }

        return lines.joined(separator: "\n")
    }
}

struct SmritiSearchTab: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var submittedQuery = ""

    private let suggestions = [
        "Help me remember",
        "What should I do now?",
        "Show my routine",
        "Start a memory chat",
    ]

    var body: some View {
        SmritiView(
            externalSearchText: $searchText,
            submittedSearchQuery: $submittedQuery
        )
        .environmentObject(appState)
        .searchable(text: $searchText, prompt: "Ask Smriti")
        .onSubmit(of: .search) {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            submittedQuery = trimmed
        }
    }
}

#Preview {
    patientTabbar()
}
