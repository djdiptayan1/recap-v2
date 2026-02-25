// JournalCard.swift
// recap
// Created by Copilot on 25/02/26.

import SwiftUI

struct JournalCard: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: 14) {
            Text(entry.moodEmoji)
                .font(.system(size: 36))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .lineLimit(1)
                }

                if let content = entry.content, !content.isEmpty {
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

            VStack(spacing: 8) {
                if entry.hasAudio {
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConfig.Colors.accent)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
            }
        }
        .padding(AppConfig.UI.padding)
        .glassEffect(.clear, in: .rect)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(
            color: Color.black.opacity(0.05),
            radius: AppConfig.UI.cardShadowRadius,
            x: 0,
            y: AppConfig.UI.cardShadowOffsetY
        )
    }
}
