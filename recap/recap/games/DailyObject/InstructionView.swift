//
//  InstructionView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct InstructionView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "43C57A"), Color(hex: "1DBBAA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Text("🏠")
                    .font(.system(size: 58))
            }
            .accessibilityHidden(true)

            Text("Daily Objects")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                DOBullet(icon: "1.circle.fill", color: Color(hex: "43C57A"),
                         text: "Look at the everyday objects shown.")
                DOBullet(icon: "2.circle.fill", color: Color(hex: "2CBFCE"),
                         text: "Try to remember all of them!")
                DOBullet(icon: "3.circle.fill", color: Color(hex: "7B4FD9"),
                         text: "Then pick the ones you saw from a bigger list.")
            }
            .padding(.horizontal, 32)

            Button(action: {
                HapticManager.shared.trigger(.selection)
                onStart()
            }) {
                Text("Let's Play!")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "43C57A"), Color(hex: "1DBBAA")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: Color(hex: "43C57A").opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
            .accessibilityLabel("Start Daily Objects")
            .accessibilityHint("Begins the memory game")
            .accessibilityInputLabels(["start game", "let's play", "daily objects"])
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .standardBackground()
    }
}

private struct DOBullet: View {
    let icon: String
    let color: Color
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 22, weight: .bold))
                .accessibilityHidden(true)
            Text(text)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}
