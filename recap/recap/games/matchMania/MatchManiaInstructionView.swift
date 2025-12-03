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
            Image(systemName: "brain.fill")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.accent)
                .padding(30)
                .background(Circle().fill(AppConfig.Colors.accent.opacity(0.1)))
            
            Text("Match Mania")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)
            
            Text("Flip cards to find matching pairs.\n\nYou can only flip 2 cards at a time.\n\nFind all pairs to win!")
                .font(AppConfig.Fonts.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundColor(AppConfig.Colors.textSecondary)
            
            Button(action: onStart) {
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

#Preview {
    MatchManiaInstructionView(onStart: {})
}
