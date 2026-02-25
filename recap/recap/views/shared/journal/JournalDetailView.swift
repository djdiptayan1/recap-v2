// JournalDetailView.swift
// recap
// Created by Copilot on 25/02/26.

import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    let patientId: String

    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConfig.UI.spacing) {
                // Mood emoji
                if entry.mood != nil {
                    HStack {
                        Spacer()
                        Text(entry.moodEmoji)
                            .font(.system(size: 64))
                        Spacer()
                    }
                    .padding(.top, AppConfig.UI.padding)
                }

                // Title
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(AppConfig.Fonts.titleMedium)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                }

                // Content
                if let content = entry.content, !content.isEmpty {
                    Text(content)
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .lineSpacing(6)
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                }

                // Audio player
                if entry.hasAudio, let audioURL = entry.audioURL {
                    audioPlayerCard(url: audioURL)
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                }

                Divider()
                    .padding(.horizontal, AppConfig.UI.screenPadding)

                // Metadata
                VStack(alignment: .leading, spacing: 6) {
                    if let createdBy = entry.createdBy {
                        HStack(spacing: 6) {
                            Image(systemName: createdBy == "family" ? "person.2.fill" : "person.fill")
                                .font(.system(size: 13))
                                .foregroundColor(AppConfig.Colors.accent)
                            Text("Added by \(createdBy.capitalized)")
                                .font(AppConfig.Fonts.small)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13))
                            .foregroundColor(AppConfig.Colors.accent)
                        Text(entry.formattedDate)
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, AppConfig.UI.screenPadding)
                .padding(.bottom, AppConfig.UI.screenPadding)
            }
        }
        .navigationTitle(entry.formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.trigger(.warning)
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(AppConfig.Colors.alert)
                }
            }
        }
        .alert("Delete Entry", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    let success = await viewModel.deleteEntry(entryId: entry.id, patientId: patientId)
                    if success {
                        HapticManager.shared.trigger(.success)
                        dismiss()
                    } else {
                        HapticManager.shared.trigger(.error)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
        }
        .standardBackground()
        .onDisappear {
            viewModel.stopAudio()
        }
    }

    private func audioPlayerCard(url: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 22))
                .foregroundColor(AppConfig.Colors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Voice Note")
                    .font(AppConfig.Fonts.bodyBold)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                if let duration = entry.audioDuration {
                    Text(formatDuration(duration))
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .monospacedDigit()
                }
            }

            Spacer()

            Button {
                HapticManager.shared.trigger(.selection)
                viewModel.playAudio(from: url, entryId: entry.id)
            } label: {
                ZStack {
                    Circle()
                        .fill(AppConfig.Colors.accent)
                        .frame(width: 52, height: 52)
                    Image(systemName: viewModel.isPlaying && viewModel.playingEntryId == entry.id ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(AppConfig.UI.padding)
        .background(AppConfig.Colors.card)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: AppConfig.UI.cardShadowRadius,
            x: 0,
            y: AppConfig.UI.cardShadowOffsetY
        )
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
