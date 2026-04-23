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
    @State private var patientId: String = ""

    // Grid layout for category filters
    let rows = [GridItem(.fixed(30))]

    var filteredReminders: [Reminder] {
        if let category = selectedCategory {
            return viewModel.reminders.filter { $0.category == category }
        }
        return viewModel.reminders
    }

    var body: some View {
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
                        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
                    Spacer()
                } else if filteredReminders.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppConfig.Colors.accent.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: selectedCategory == nil ? "bell.badge.fill" : "bell.slash")
                                .font(.system(size: 44))
                                .foregroundColor(AppConfig.Colors.accent.opacity(0.7))
                        }
                        VStack(spacing: 8) {
                            Text(selectedCategory == nil ? "No Reminders Yet" : "No \(selectedCategory!.rawValue) Reminders")
                                .font(AppConfig.Fonts.titleMedium)
                                .foregroundColor(AppConfig.Colors.textPrimary)
                            Text(selectedCategory == nil ? "Stay on track by adding your first reminder." : "No reminders found in this category.")
                                .font(AppConfig.Fonts.body)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppConfig.UI.screenPadding)
                        }
                        if selectedCategory == nil {
                            Button {
                                HapticManager.shared.trigger(.selection)
                                reminderToEdit = nil
                                showingAddSheet = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                    Text("Create First Reminder")
                                }
                                .font(AppConfig.Fonts.bodyBold)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 28)
                                .background(AppConfig.Colors.accent)
                                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                            }
                            .padding(.top, 8)
                            .accessibilityLabel("Create first reminder")
                            .accessibilityInputLabels(["add reminder", "new reminder", "create reminder"])
                        }
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
                                    Button {
                                        Task {
                                            _ = await viewModel.markReminderCompleted(
                                                patientId: patientId,
                                                reminderId: reminder.id,
                                                completedVia: "in_app"
                                            )
                                        }
                                    } label: {
                                        Label("Done", systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)

                                    Button {
                                        reminderToEdit = reminder
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.trigger(.warning)
                                        reminderToDelete = reminder
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(AppConfig.Colors.alert)
                                }
                                .contextMenu {
                                    Button {
                                        Task {
                                            _ = await viewModel.markReminderCompleted(
                                                patientId: patientId,
                                                reminderId: reminder.id,
                                                completedVia: "in_app"
                                            )
                                        }
                                    } label: {
                                        Label("Mark as Done", systemImage: "checkmark.circle.fill")
                                    }

                                    Button {
                                        reminderToEdit = reminder
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        reminderToDelete = reminder
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            patientId =
                KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?
                .id ?? ""
            if !patientId.isEmpty {
                Task {
                    await viewModel.fetchReminders(patientId: patientId)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet, onDismiss: { reminderToEdit = nil }) {
            AddReminderSheet(
                viewModel: viewModel,
                patientId: patientId,
                reminderToEdit: nil
            )
        }
        .sheet(item: $reminderToEdit) { reminder in
            AddReminderSheet(
                viewModel: viewModel,
                patientId: patientId,
                reminderToEdit: reminder
            )
        }
        .alert(
            "Delete Reminder?", isPresented: $showDeleteConfirmation,
            presenting: reminderToDelete
        ) { reminder in
            Button("Cancel", role: .cancel) {
                reminderToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    let success = await viewModel.deleteReminder(patientId: patientId, reminderId: reminder.id)
                    if success {
                        withAnimation {
                            reminderToDelete = nil
                        }
                    }
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
                .accessibilityLabel("Add reminder")
                .accessibilityHint("Opens the reminder editor")
                .accessibilityInputLabels(["add reminder", "new reminder", "plus"])
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
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityInputLabels([title.lowercased(), "filter", "reminders"])
    }
}

struct ReminderCard: View {
    let reminder: Reminder

    private var statusText: String? {
        if let lastAction = reminder.lastAction,
            let lastActionAt = reminder.lastActionAt
        {
            switch lastAction {
            case "completed":
                return "Last done: \(lastActionAt.formatted(date: .abbreviated, time: .shortened))"
            case "snoozed":
                return "Snoozed until: \((reminder.lastSnoozedUntil ?? lastActionAt).formatted(date: .omitted, time: .shortened))"
            default:
                return nil
            }
        }
        return nil
    }

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

                // Category-Specific Details
                if let details = reminder.categoryDetails, !details.isEmpty {
                    CategoryDetailsView(category: reminder.category, details: details)
                        .padding(.top, 4)
                }

                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                if let statusText {
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
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

/// Displays category-specific detail chips/labels for a reminder card
struct CategoryDetailsView: View {
    let category: ReminderCategory
    let details: [String: String]

    var body: some View {
        let fields = category.detailFields.filter { details[$0.key] != nil && !details[$0.key]!.isEmpty }
        if !fields.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(fields) { field in
                    if let value = details[field.key], !value.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: field.icon)
                                .font(.system(size: 10))
                            Text("\(field.label): \(value)")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(category.color.opacity(0.1))
                        .foregroundColor(category.color)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

/// A simple horizontal flow layout that wraps items to the next line
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}

#Preview() {
    remindersView()
}
