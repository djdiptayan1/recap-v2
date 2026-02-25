// JournalView.swift
// recap
// Created by Copilot on 25/02/26.

import SwiftUI

struct JournalView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingCompose = false
    @State private var patientId: String = ""

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.entries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.entries) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry, viewModel: viewModel, patientId: patientId)) {
                            JournalCard(entry: entry)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                                Task {
                                    await viewModel.deleteEntry(entryId: entry.id, patientId: patientId)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(AppConfig.Colors.alert)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.fetchEntries(patientId: patientId)
                }
                // Subtle top-of-list loading bar when refreshing existing entries
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppConfig.Colors.accent))
                            .padding(.top, 8)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("My Journal")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.trigger(.selection)
                    showingCompose = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConfig.Colors.accent)
                }
            }
        }
        .sheet(isPresented: $showingCompose, onDismiss: {
            Task { await viewModel.fetchEntries(patientId: patientId) }
        }) {
            JournalComposeView(viewModel: viewModel, patientId: patientId)
        }
        .standardBackground()
        .onAppear {
            patientId = KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?.id ?? ""
            if !patientId.isEmpty && viewModel.entries.isEmpty {
                Task { await viewModel.fetchEntries(patientId: patientId) }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppConfig.UI.spacing) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundColor(AppConfig.Colors.accent.opacity(0.7))

            Text("Your Journal Awaits")
                .font(AppConfig.Fonts.titleMedium)
                .foregroundColor(AppConfig.Colors.textPrimary)

            Text("Start capturing your thoughts and memories today.")
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConfig.UI.screenPadding)

            Button {
                HapticManager.shared.trigger(.selection)
                showingCompose = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                    Text("Write First Entry")
                }
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(AppConfig.Colors.accent)
                .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        JournalView()
            .environmentObject(AppState())
    }
}
