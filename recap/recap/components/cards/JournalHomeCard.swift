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
                    Text("My Journal")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                }
                .padding(AppConfig.UI.padding)

                Divider()
                    .background(AppConfig.Colors.stroke)
                    .padding(.horizontal, AppConfig.UI.padding)

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capture your memories")
                            .font(AppConfig.Fonts.bodyBold)
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text("Write or record your thoughts and feelings every day.")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(4)
                    }

                    Spacer()

                    ZStack {
//                        Circle()
//                            .fill(AppConfig.Colors.accent.opacity(0.15))
//                            .frame(width: 64, height: 64)
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppConfig.Colors.accent)
                    }
                }
                .padding(20)
            }
            .glassEffect(.clear, in: .rect)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: AppConfig.UI.cardShadowRadius,
                x: 0,
                y: AppConfig.UI.cardShadowOffsetY
            )
        }
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
