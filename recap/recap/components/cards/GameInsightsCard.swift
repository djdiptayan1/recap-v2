//
//  GameInsightsCard.swift
//  recap
//

import SwiftUI

struct GameInsightsCard: View {
    @ObservedObject var viewModel: GameAnalyticsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Game Insights")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppConfig.Colors.accent)
                }
            }

            if let analytics = viewModel.analytics {
                HStack(spacing: 12) {
                    statPill(title: "7 Days", value: "\(analytics.overall.sessionsLast7Days)")
                    statPill(title: "Accuracy", value: "\(Int(analytics.overall.averageAccuracy))%")
//                    statPill(title: "Favorite", value: RecapGameType(rawValue: analytics.overall.favoriteGame ?? "")?.displayName ?? "No data")
                }

                if let best = analytics.byGame.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best recent signal")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)

                        Text("\(best.displayName) is the most active game with an average score of \(Int(best.averageScore)).")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.alert)
            } else {
                Text("Play a few sessions to unlock game trends.")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }
        }
        .padding(18)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game insights")
        .accessibilityHint("Shows recent game activity and trends")
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
            Text(value)
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppConfig.Colors.card.opacity(0.9))
        .cornerRadius(14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
