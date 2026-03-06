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
                    for: reminder.time, calendar: NotificationManager.istCalendar)
                {
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

    /// Short one-liner for the notification banner (always visible).
    /// e.g. "Medicine · 9:47 PM · Daily"
    private static func buildNotificationSubtitle(for reminder: Reminder) -> String {
        let timeString = reminder.time.formatted(date: .omitted, time: .shortened)
        return "\(reminder.category.rawValue) · \(timeString) · \(reminder.frequency.displayName)"
    }

    /// Full details shown only when the notification is expanded (long-press).
    /// Works generically for ALL categories using their `detailFields`.
    private static func buildNotificationBody(for reminder: Reminder) -> String {
        var lines: [String] = []

        if let details = reminder.categoryDetails, !details.isEmpty {
            // Track which keys we've already handled (for unit merging)
            var handledKeys: Set<String> = []
            let fields = reminder.category.detailFields

            for field in fields {
                guard !handledKeys.contains(field.key) else { continue }
                guard let value = details[field.key], !value.isEmpty else { continue }

                // Check if the next field is a unit field for this value
                // e.g. "dosage" + "dosageUnit", "amount" + "unit"
                let unitField = fields.first {
                    $0.key == "\(field.key)Unit" || ($0.key == "unit" && field.key == "amount")
                }
                if let unitField, let unitValue = details[unitField.key], !unitValue.isEmpty {
                    lines.append("\(field.label): \(value) \(unitValue)")
                    handledKeys.insert(unitField.key)
                } else if field.key.hasSuffix("Unit") || (field.key == "unit") {
                    // Skip standalone unit fields — they're merged above
                    continue
                } else {
                    lines.append("\(field.label): \(value)")
                }
                handledKeys.insert(field.key)
            }
        }

        // Add notes if present
        if let notes = reminder.notes, !notes.isEmpty {
            lines.append("\(notes)")
        }

        // Fallback if no details at all
        if lines.isEmpty {
            return "It's time for your \(reminder.category.rawValue) reminder!"
        }

        return lines.joined(separator: "\n")
    }
}

#Preview {
    patientTabbar()
}
