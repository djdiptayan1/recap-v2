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

                Section(header: Text("Time")) {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
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
                    if let reminder = reminderToEdit {
                        viewModel.editReminder(
                            patientId: patientId,
                            reminderId: reminder.id,
                            title: title,
                            category: selectedCategory,
                            frequency: selectedFrequency,
                            time: time,
                            notes: notes
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
                            notes: notes
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
                }
            }
        }
    }
}
