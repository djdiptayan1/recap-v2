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
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.accent)
                .padding(.bottom, 10)
            
            Text("Round Complete!")
                .font(AppConfig.Fonts.titleLarge)
                .foregroundColor(AppConfig.Colors.textPrimary)
            
            VStack(spacing: 8) {
                Text("Current Score")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppConfig.Colors.textPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
            
            Button(action: onNext) {
                Text("Next Round")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppConfig.Colors.accent)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
}

#Preview {
    RoundSummaryView(score: 150, onNext: {})
}
