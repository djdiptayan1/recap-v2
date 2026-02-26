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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)

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
                            } else {
                                HStack {
                                    Label(field.label, systemImage: field.icon)
                                        .foregroundColor(AppConfig.Colors.textSecondary)
                                    TextField(field.placeholder, text: Binding(
                                        get: { categoryDetailsValues[field.key] ?? "" },
                                        set: { categoryDetailsValues[field.key] = $0 }
                                    ))
                                    .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("When to Remind")) {
                    DatePicker("Reminder Time", selection: $time, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(reminderToEdit != nil ? "Edit Reminder" : "New Reminder")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let details = buildCategoryDetails()
                    if let reminder = reminderToEdit {
                        viewModel.editReminder(
                            patientId: patientId,
                            reminderId: reminder.id,
                            title: title,
                            category: selectedCategory,
                            frequency: selectedFrequency,
                            time: time,
                            notes: notes,
                            categoryDetails: details
                        ) { success in
                            if success { dismiss() }
                        }
                    } else {
                        viewModel.addReminder(
                            patientId: patientId,
                            title: title,
                            category: selectedCategory,
                            frequency: selectedFrequency,
                            time: time,
                            notes: notes,
                            categoryDetails: details
                        ) { success in
                            if success { dismiss() }
                        }
                    }
                }
                .disabled(title.isEmpty)
            )
            .onAppear {
                if let reminder = reminderToEdit {
                    title = reminder.title
                    selectedCategory = reminder.category
                    selectedFrequency = reminder.frequency
                    time = reminder.time
                    notes = reminder.notes ?? ""
                    categoryDetailsValues = reminder.categoryDetails ?? [:]
                }
            }
            .onChange(of: selectedCategory) { _ in
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
