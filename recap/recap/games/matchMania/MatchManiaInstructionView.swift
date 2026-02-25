//
//  MatchManiaInstructionView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct MatchManiaInstructionView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "FFAA5C")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Text("🧠")
                    .font(.system(size: 58))
            }

            Text("Match Mania")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                MMBullet(icon: "1.circle.fill", color: Color(hex: "FF6B35"),
                         text: "Tap any card to flip it over.")
                MMBullet(icon: "2.circle.fill", color: Color(hex: "FFAA5C"),
                         text: "Flip a second card to find its match.")
                MMBullet(icon: "checkmark.circle.fill", color: Color(hex: "43C57A"),
                         text: "Find all 8 pairs to win! Fewer moves = better score.")
            }
            .padding(.horizontal, 32)

            Button(action: onStart) {
                Text("Let's Play! 🃏")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "FFAA5C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: Color(hex: "FF6B35").opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .standardBackground()
    }
}

private struct MMBullet: View {
    let icon: String
    let color: Color
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 22, weight: .bold))
            Text(text)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}

#Preview {
    MatchManiaInstructionView(onStart: {})
}
