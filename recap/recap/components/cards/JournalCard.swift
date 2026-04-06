// JournalCard.swift
// recap
// Created by Copilot on 25/02/26.

import SDWebImageSwiftUI
import SwiftUI

struct JournalCard: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 14) {
            // Leading: photo thumbnail for memories, mood emoji for journal entries
            if entry.hasPhotos, let firstPhotoURL = entry.photos?.first?.url {
                let thumbnailURL = entry.photos?.first?.thumbnailURL ?? firstPhotoURL
                WebImage(url: URL(string: thumbnailURL))
                    .resizable()
                    .indicator(.activity)
                    .transition(AnyTransition.fade(duration: 0.3))
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text(entry.moodEmoji)
                    .font(.system(size: 36))
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(AppConfig.Fonts.bodyBold)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                            .lineLimit(1)
                    }
                    // Badge for memory entries
                    if entry.isMemory {
                        Text("Memory")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppConfig.Colors.accent)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(AppConfig.Colors.accent.opacity(0.12))
                            .cornerRadius(6)
                    }
                }

                // Subtitle: place/people for memories, content preview for journal
                if entry.isMemory {
                    let subtitle = [entry.people, entry.place, entry.eventTag]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: " · ")
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .lineLimit(1)
                    }
                } else if let content = entry.content, !content.isEmpty {
                    Text(content)
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(2)
                }

                Text(entry.formattedDate)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.7))
            }

            Spacer()

            VStack(spacing: 6) {
                if entry.hasPhotos {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppConfig.Colors.accent)
                } else if entry.hasAudio {
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppConfig.Colors.accent)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .padding(AppConfig.UI.padding)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
        .shadow(
            color: Color.black.opacity(0.05),
            radius: AppConfig.UI.cardShadowRadius,
            x: 0,
            y: AppConfig.UI.cardShadowOffsetY
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            {
                var label = entry.title ?? "Journal entry"
                if entry.isMemory { label += ", Memory" }
                label += ", \(entry.formattedDate)"
                if entry.hasPhotos { label += ", has photos" }
                if entry.hasAudio { label += ", has audio" }
                return label
            }()
        )
        .accessibilityHint("Tap to read this journal entry.")
        .accessibilityAddTraits(.isButton)
    }
}
