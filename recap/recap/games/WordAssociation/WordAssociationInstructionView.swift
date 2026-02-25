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
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.accent)
                .padding(30)
                .background(Circle().fill(AppConfig.Colors.accent.opacity(0.1)))

            Text("Word Link")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                InstructionBullet(icon: "1.circle.fill", text: "A category word will be shown at the top.")
                InstructionBullet(icon: "2.circle.fill", text: "Select all words that belong to that category.")
                InstructionBullet(icon: "3.circle.fill", text: "Tap Submit when you're done.")
                InstructionBullet(icon: "4.circle.fill", text: "Green = correct, Red = wrong. Try to get all 8 rounds!")
            }
            .padding(.horizontal, 32)

            Button(action: {
                HapticManager.shared.trigger(.selection)
                onStart()
            }) {
                Text("Start Game")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 56)
                    .background(AppConfig.Colors.accent)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .standardBackground()
    }
}

private struct InstructionBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppConfig.Colors.accent)
                .font(.system(size: 20, weight: .bold))
            Text(text)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
    }
}

#Preview {
    WordAssociationInstructionView(onStart: {})
}
