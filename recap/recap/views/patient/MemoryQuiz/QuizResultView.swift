//
//  QuizResultView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct QuizResultView: View {
    let result: QuizResult
    let onRestart: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Score Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(result.color.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: result.icon)
                            .font(.system(size: 40))
                            .foregroundColor(result.color)
                    }
                    
                    Text("Your Score: \(result.score) / \(result.totalQuestions)")
                        .font(AppConfig.Fonts.titleMedium)
                        .foregroundColor(AppConfig.Colors.textPrimary)
                }
                .padding(.top, 40)
                
                // Result Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(result.title)
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(result.color)
                    
                    Divider()
                    
                    Text(result.description)
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineSpacing(6)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                
                // Disclaimer
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("This quiz is for awareness only and does not constitute a medical diagnosis.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 20)
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: onExit) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppConfig.Colors.textPrimary)
                            .cornerRadius(16)
                    }
                    
                    Button(action: onRestart) {
                        Text("Retake Quiz")
                            .font(.subheadline)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(AppConfig.UI.screenPadding)
        }
    }
}
