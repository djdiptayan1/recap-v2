//
//  RoundSummaryView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct RoundSummaryView: View {
    let score: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("⭐️")
                .font(.system(size: 80))
                .accessibilityHidden(true)

            Text("Round Complete!")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(spacing: 6) {
                Text("Score")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                Text("\(score)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: "43C57A"), Color(hex: "1DBBAA")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(color: Color(hex: "43C57A").opacity(0.3), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)

            Button(action: {
                HapticManager.shared.trigger(.selection)
                onNext()
            }) {
                Text("Next Round →")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "43C57A"), Color(hex: "1DBBAA")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: Color(hex: "43C57A").opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
            .accessibilityLabel("Next round")
            .accessibilityHint("Moves to the next set of objects")
            .accessibilityInputLabels(["next round", "continue", "keep going"])
        }
    }
}

#Preview {
    RoundSummaryView(score: 150, onNext: {})
}
