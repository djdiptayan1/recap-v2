//
//  PatternMemoryInstructionView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

struct PatternMemoryInstructionView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.accent)
                .padding(30)
                .background(Circle().fill(AppConfig.Colors.accent.opacity(0.1)))

            Text("Pattern Memory")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 12) {
                PMInstructionBullet(icon: "1.circle.fill", text: "Watch the colored tiles light up in a sequence.")
                PMInstructionBullet(icon: "2.circle.fill", text: "Repeat the same sequence by tapping the tiles.")
                PMInstructionBullet(icon: "3.circle.fill", text: "Each round adds one more step to the sequence.")
                PMInstructionBullet(icon: "heart.fill",    text: "You have 2 lives — good luck!")
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
//        .standardBackground()
    }
}

private struct PMInstructionBullet: View {
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
    PatternMemoryInstructionView(onStart: {})
}
