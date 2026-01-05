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
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.accent)
                .padding(30)
                .background(Circle().fill(AppConfig.Colors.accent.opacity(0.1)))

            Text("Memory Training")
                .font(AppConfig.Fonts.titleLarge)

            Text(
                "We will show you a set of everyday objects.\n\nTry to remember them, then select them from a list."
            )
            .font(AppConfig.Fonts.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .foregroundColor(AppConfig.Colors.textSecondary)

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
    }
}
