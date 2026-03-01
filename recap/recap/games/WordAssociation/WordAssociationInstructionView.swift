//
//  WordAssociationInstructionView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

struct WordAssociationInstructionView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "7B4FD9"), Color(hex: "B067E8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Text("💬")
                    .font(.system(size: 58))
            }

            Text("Word Link")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 14) {
                InstructionBullet(icon: "1.circle.fill", text: "A category word is shown at the top.")
                InstructionBullet(icon: "2.circle.fill", text: "Select all words that belong to that category.")
                InstructionBullet(icon: "3.circle.fill", text: "Tap Submit when you're done.")
                InstructionBullet(icon: "star.fill",     text: "Green = correct, Red = wrong. 8 rounds total!")
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
                            colors: [Color(hex: "7B4FD9"), Color(hex: "B067E8")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: Color(hex: "7B4FD9").opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .standardBackground()
    }
}

private struct InstructionBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "7B4FD9"))
                .font(.system(size: 22, weight: .bold))
            Text(text)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}

#Preview {
    WordAssociationInstructionView(onStart: {})
}
