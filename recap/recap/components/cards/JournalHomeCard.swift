// JournalHomeCard.swift
// recap
// Created by Copilot on 25/02/26.

import SwiftUI

/// Home-screen entry card that navigates to the patient's full Journal.
/// Styled to match LetsReadCard and QuestionsCard.
struct JournalHomeCard: View {
    var body: some View {
        NavigationLink(destination: JournalView()) {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Journal")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                        .accessibilityHidden(true)
                }
                .padding(AppConfig.UI.padding)

                Divider()
                    .background(AppConfig.Colors.stroke)
                    .padding(.horizontal, AppConfig.UI.padding)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Capture your thoughts")
                        .font(AppConfig.Fonts.bodyBold)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text("Writing helps preserve memories and track your journey.")
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppConfig.UI.padding)
                .padding(.vertical, 14)
            }
            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
            .shadow(
                color: Color.black.opacity(0.05),
                radius: AppConfig.UI.cardShadowRadius,
                x: 0,
                y: AppConfig.UI.cardShadowOffsetY
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Journal")
        .accessibilityHint("Capture your thoughts. Tap to open your journal.")
        .accessibilityAddTraits(.isButton)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        JournalHomeCard()
            .padding()
    }
    .standardBackground()
}
