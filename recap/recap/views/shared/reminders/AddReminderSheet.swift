//
//  AddReminderSheet.swift
//  recap
//
//  Created by Diptayan Jash on 18/01/26.
//

import SwiftUI

struct AddReminderSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReminderViewModel
    let patientId: String
    var reminderToEdit: Reminder? = nil  // Optional reminder to edit

    @State private var title = ""
    @State private var selectedCategory: ReminderCategory = .medicine
    @State private var selectedFrequency: ReminderFrequency = .daily
    @State private var time = Date()
    @State private var notes = ""
    @State private var categoryDetailsValues: [String: String] = [:]
    @State private var isHydratingFromReminder = false

    private func reminderFieldInputLabels(_ label: String, fallback: String? = nil) -> [LocalizedStringKey] {
        var labels: [LocalizedStringKey] = [LocalizedStringKey(label)]
        if let fallback, !fallback.isEmpty {
            labels.append(LocalizedStringKey(fallback))
        }

        let lowercased = label.lowercased()
        if lowercased.contains("title") {
            labels.append(contentsOf: ["reminder title", "name"])
        }
        if lowercased.contains("time") {
            labels.append(contentsOf: ["reminder time", "when"])
        }
        if lowercased.contains("notes") {
            labels.append(contentsOf: ["reminder notes", "details"])
        }

        return labels
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Reminder title")
                        .accessibilityHint("Enter the name of the reminder")
                        .accessibilityInputLabels(reminderFieldInputLabels("Reminder title", fallback: "title"))

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ReminderCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }

                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(ReminderFrequency.allCases) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                }

                // Category-Specific Details Section
                if !selectedCategory.detailFields.isEmpty {
                    Section(header: Label("\(selectedCategory.rawValue) Details", systemImage: selectedCategory.icon)) {
                        ForEach(selectedCategory.detailFields) { field in
                            if let options = field.pickerOptions {
                                Picker(selection: Binding(
                                    get: { categoryDetailsValues[field.key] ?? "" },
                                    set: { categoryDetailsValues[field.key] = $0 }
                                )) {
                                    Text(field.placeholder).tag("")
                                    ForEach(options, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                } label: {
                                    Label(field.label, systemImage: field.icon)
                                }
                                .accessibilityLabel(field.label)
                                .accessibilityInputLabels(reminderFieldInputLabels(field.label, fallback: field.placeholder))
                            } else {
                                HStack {
                                    Label(field.label, systemImage: field.icon)
                                        .foregroundColor(AppConfig.Colors.textSecondary)
                                    TextField(field.placeholder, text: Binding(
                                        get: { categoryDetailsValues[field.key] ?? "" },
                                        set: { categoryDetailsValues[field.key] = $0 }
                                    ))
                                    .multilineTextAlignment(.trailing)
                                    .accessibilityLabel(field.label)
                                    .accessibilityInputLabels(reminderFieldInputLabels(field.label, fallback: field.placeholder))
                                }
                            }
                        }
                    }
                }

                Section(header: Text("When to Remind")) {
                    DatePicker("Reminder Time", selection: $time, displayedComponents: .hourAndMinute)
                        .accessibilityLabel("Reminder time")
                        .accessibilityInputLabels(reminderFieldInputLabels("Reminder time", fallback: "time"))
                }

                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .accessibilityLabel("Reminder notes")
                        .accessibilityHint("Optional additional details for this reminder")
                        .accessibilityInputLabels(reminderFieldInputLabels("Reminder notes", fallback: "notes"))
                }
            }
            .navigationTitle(reminderToEdit != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let details = buildCategoryDetails()
                    if let reminder = reminderToEdit {
                        Task {
                            let success = await viewModel.editReminder(
                                patientId: patientId,
                                reminderId: reminder.id,
                                title: title,
                                category: selectedCategory,
                                frequency: selectedFrequency,
                                time: time,
                                notes: notes,
                                categoryDetails: details
                            )
                            if success { dismiss() }
                        }
                    } else {
                        Task {
                            let success = await viewModel.addReminder(
                                patientId: patientId,
                                title: title,
                                category: selectedCategory,
                                frequency: selectedFrequency,
                                time: time,
                                notes: notes,
                                categoryDetails: details
                            )
                            if success { dismiss() }
                        }
                    }
                }
                .disabled(title.isEmpty)
            )
            .onAppear {
                if let reminder = reminderToEdit {
                    isHydratingFromReminder = true
                    title = reminder.title
                    selectedCategory = reminder.category
                    selectedFrequency = reminder.frequency
                    time = reminder.time
                    notes = reminder.notes ?? ""
                    categoryDetailsValues = reminder.categoryDetails ?? [:]
                    DispatchQueue.main.async {
                        isHydratingFromReminder = false
                    }
                }
            }
            .onChange(of: selectedCategory) { _ in
                if isHydratingFromReminder { return }
                categoryDetailsValues = [:]
            }
        }
    }

    /// Filters out empty values and returns nil if no details are present
    private func buildCategoryDetails() -> [String: String]? {
        let filtered = categoryDetailsValues.filter { !$0.value.isEmpty }
        return filtered.isEmpty ? nil : filtered
    }
}
