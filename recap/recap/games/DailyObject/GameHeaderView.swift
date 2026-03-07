//
//  GameHeaderView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct GameHeaderView: View {
    let round: Int
    let score: Int
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }
            .accessibilityLabel("Close game")
            .accessibilityHint("Dismisses Daily Objects and returns to the previous screen.")
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Daily Objects")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Round \(round) • Score: \(score)")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Daily Objects")
            .accessibilityValue("Round \(round), score \(score)")
            
            Spacer()
            
            // Invisible view to balance the center text
            Image(systemName: "xmark.circle.fill").font(.system(size: 28)).opacity(0)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .overlay(Rectangle().frame(height: 1).foregroundColor(AppConfig.Colors.stroke), alignment: .bottom)
    }
}
