//
//  DetailedAnalyticsView.swift
//  recap
//
//  Created by Diptayan Jash on 12/12/25.
//

import SwiftUI
import Charts

struct DetailedAnalyticsView: View {
    let timeFrame: TimeFrame
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppConfig.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: iconForType)
                            .font(.system(size: 50))
                            .foregroundColor(AppConfig.Colors.accent)
                            .padding()
                            .background(Circle().fill(AppConfig.Colors.accent.opacity(0.1)))
                        
                        Text("\(timeFrame.rawValue) Report")
                            .font(AppConfig.Fonts.titleMedium)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                        
                        Text("Detailed breakdown of your cognitive performance.")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Detail Content Placeholder
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analysis")
                            .font(AppConfig.Fonts.headline)
                        
                        Text("Your performance in the \(timeFrame.rawValue) category indicates stability. Consistency is key for long-term brain health.")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .lineSpacing(6)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var iconForType: String {
        switch timeFrame {
        case .immediate: return "sun.max.fill"
        case .recent: return "calendar"
        case .remote: return "clock.arrow.circlepath"
        }
    }
}
