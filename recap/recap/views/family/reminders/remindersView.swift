//
//  remindersView.swift
//  recap
//
//  Created by Diptayan Jash on 18/01/26.
//

import SwiftUI

struct remindersView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: ReminderViewModel

    init(viewModel: ReminderViewModel = ReminderViewModel()) {
        self.viewModel = viewModel
    }

    @State private var showingAddSheet = false
    @State private var selectedCategory: ReminderCategory? = nil
    @State private var reminderToEdit: Reminder? = nil
    @State private var reminderToDelete: Reminder? = nil
    @State private var showDeleteConfirmation = false

    // Grid layout for category filters
    let rows = [GridItem(.fixed(30))]

    var filteredReminders: [Reminder] {
        if let category = selectedCategory {
            return viewModel.reminders.filter { $0.category == category }
        }
        return viewModel.reminders
    }

    var body: some View {
        let patientId =
            KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?.id
            ?? ""
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                //                // Header
                //                HStack {
                //                    Text("Reminders")
                //                        .font(AppConfig.Fonts.titleLarge)
                //                        .foregroundColor(AppConfig.Colors.textPrimary)
                //                    Spacer()
                //                    Button(action: {
                //                        reminderToEdit = nil
                //                        showingAddSheet = true
                //                    }) {
                //                        Image(systemName: "plus.circle.fill")
                //                            .font(.system(size: 32))
                //                            .foregroundColor(AppConfig.Colors.accent)
                //                    }
                //                }
                //                .padding(.horizontal, AppConfig.UI.screenPadding - 10)
                //                .padding(.top, 20)

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            color: AppConfig.Colors.accent
                        ) {
                            withAnimation { selectedCategory = nil }
                        }

                        ForEach(ReminderCategory.allCases) { category in
                            CategoryFilterChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                color: category.color
                            ) {
                                withAnimation { selectedCategory = category }
                            }
                        }
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding - 10)
                }

                // Reminders List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredReminders.isEmpty {
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Text("No reminders found")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List {
                        ForEach(filteredReminders) { reminder in
                            ReminderCard(reminder: reminder)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 8, leading: AppConfig.UI.screenPadding - 10, bottom: 8,
                                        trailing: AppConfig.UI.screenPadding - 10)
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.trigger(.warning)
                                        reminderToDelete = reminder
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(AppConfig.Colors.alert)

                                    Button {
                                        reminderToEdit = reminder
                                        showingAddSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            if !patientId.isEmpty {
                viewModel.fetchReminders(patientId: patientId)
            }
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: { reminderToEdit = nil }) {
            AddReminderSheet(
                viewModel: viewModel, patientId: patientId, reminderToEdit: reminderToEdit)
        }
        .alert(
            "Delete Reminder?", isPresented: $showDeleteConfirmation,
            presenting: reminderToDelete
        ) { reminder in
            Button("Cancel", role: .cancel) {
                reminderToDelete = nil
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    viewModel.deleteReminder(patientId: patientId, reminderId: reminder.id)
                }
            }
        } message: { reminder in
            Text(
                "Are you sure you want to delete \"\(reminder.title)\"? This action cannot be undone."
            )
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    reminderToEdit = nil
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .standardBackground()
    }
}

// MARK: - Subviews

struct CategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppConfig.Fonts.small)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : AppConfig.Colors.card)
                .foregroundColor(isSelected ? .white : AppConfig.Colors.textPrimary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppConfig.Colors.stroke, lineWidth: isSelected ? 0 : 1)
                )
                .shadow(
                    color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.05), radius: 4,
                    x: 0, y: 2)
        }
    }
}

struct ReminderCard: View {
    let reminder: Reminder

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(reminder.category.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: reminder.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(reminder.category.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.title)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                HStack(spacing: 12) {
                    Label {
                        Text(reminder.time.formatted(date: .omitted, time: .shortened))
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                    Label {
                        Text(reminder.frequency.displayName)
                    } icon: {
                        Image(systemName: "repeat")
                    }
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                }

                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(AppConfig.Colors.card)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: AppConfig.UI.cardShadowRadius,
            x: 0,
            y: AppConfig.UI.cardShadowOffsetY
        )
    }
}

#Preview() {
    remindersView()
}
