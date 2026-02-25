//
//  WordAssociationResultView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

struct WordAssociationCompletionOverlay: View {
    let score: Int
    let accuracy: Int
    let onRestart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)

                Text("Well Done!")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                VStack(spacing: 8) {
                    Text("Score: \(score)")
                    Text("Accuracy: \(accuracy)%")
                }
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)

                HStack(spacing: 16) {
                    Button(action: onDismiss) {
                        Text("Exit")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .frame(width: 100, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    }

                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(.white)
                            .frame(width: 140, height: 50)
                            .background(AppConfig.Colors.accent)
                            .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    }
                }
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}
