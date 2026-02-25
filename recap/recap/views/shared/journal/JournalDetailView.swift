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
    @State private var fullscreenPhoto: JournalPhoto? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConfig.UI.spacing) {

                // Photo gallery (memory entries)
                if entry.hasPhotos, let photos = entry.photos {
                    photoGallery(photos: photos)
                }

                // Mood emoji (journal entries or when no photo)
                if entry.mood != nil && !entry.hasPhotos {
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

                // Memory metadata chips
                if entry.isMemory {
                    memoryMetadataRow
                }

                // Audio player
                if entry.hasAudio, let audioURL = entry.audioURL {
                    audioPlayerCard(url: audioURL)
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                }

                Divider()
                    .padding(.horizontal, AppConfig.UI.screenPadding)

                // Footer metadata
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
        .navigationTitle(entry.isMemory ? "Memory" : entry.formattedDate)
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
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .sheet(item: $fullscreenPhoto) { photo in
            fullscreenPhotoView(photo: photo)
        }
        .standardBackground()
        .onDisappear {
            viewModel.stopAudio()
        }
    }

    // MARK: - Photo Gallery

    private func photoGallery(photos: [JournalPhoto]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if photos.count == 1 {
                // Single photo — full width
                singlePhotoView(photo: photos[0])
            } else {
                // Multiple photos — horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos) { photo in
                            Button { fullscreenPhoto = photo } label: {
                                AsyncImage(url: URL(string: photo.url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color(AppConfig.Colors.stroke)
                                        .overlay(ProgressView())
                                }
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding)
                }
            }

            // Captions
            let captioned = photos.filter { !($0.caption?.isEmpty ?? true) }
            if !captioned.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(captioned) { photo in
                        if let caption = photo.caption {
                            Text("· \(caption)")
                                .font(AppConfig.Fonts.small)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                                .padding(.horizontal, AppConfig.UI.screenPadding)
                        }
                    }
                }
            }
        }
    }

    private func singlePhotoView(photo: JournalPhoto) -> some View {
        Button { fullscreenPhoto = photo } label: {
            AsyncImage(url: URL(string: photo.url)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color(AppConfig.Colors.stroke)
                    .overlay(ProgressView())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func fullscreenPhotoView(photo: JournalPhoto) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AsyncImage(url: URL(string: photo.url)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                ProgressView().tint(.white)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                fullscreenPhoto = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }

    // MARK: - Memory Metadata

    @ViewBuilder
    private var memoryMetadataRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let people = entry.people, !people.isEmpty {
                    metadataChip(icon: "person.2.fill", text: people)
                }
                if let place = entry.place, !place.isEmpty {
                    metadataChip(icon: "mappin.circle.fill", text: place)
                }
                if let tag = entry.eventTag, !tag.isEmpty {
                    metadataChip(icon: "tag.fill", text: tag)
                }
                if let mood = entry.mood, !mood.isEmpty {
                    metadataChip(icon: nil, text: entry.moodEmoji + " " + mood.capitalized)
                }
            }
            .padding(.horizontal, AppConfig.UI.screenPadding)
        }
    }

    private func metadataChip(icon: String?, text: String) -> some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(AppConfig.Colors.accent)
            }
            Text(text)
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textPrimary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(AppConfig.Colors.accent.opacity(0.1))
        .cornerRadius(20)
    }

    // MARK: - Audio Player Card

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
