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
    @ObservedObject var viewModel: AnalyticsViewModel
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
                        
                        Text("Detailed breakdown of cognitive performance.")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Decline Alert
                    if let alert = viewModel.declineAlert, alert.detected {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                                Text("Decline Alert")
                                    .font(AppConfig.Fonts.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            Text(alert.message)
                                .font(AppConfig.Fonts.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                            
                            // Weekly scores trend
                            HStack(spacing: 12) {
                                ForEach(Array(alert.weeklyScores.enumerated()), id: \.offset) { index, score in
                                    VStack(spacing: 4) {
                                        Text("W\(index + 1)")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text("\(Int(score))%")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(20)
                        .background(AppConfig.Colors.alert)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    
                    // Stats based on selected timeframe
                    switch timeFrame {
                    case .immediate:
                        dailyDetailSection
                    case .recent:
                        weeklyDetailSection
                    case .remote:
                        monthlyDetailSection
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Daily Detail
    
    private var dailyDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Today's Performance")
            
            if viewModel.dailyData.isEmpty {
                emptyStateView(message: "No questions answered today yet.")
            } else {
                let correct = viewModel.dailyData.first(where: { $0.label == "Correct" })?.value ?? 0
                let incorrect = viewModel.dailyData.first(where: { $0.label == "Incorrect" })?.value ?? 0
                let total = correct + incorrect
                let percentage = total > 0 ? Int((correct / total) * 100) : 0
                
                HStack(spacing: 16) {
                    StatCard(
                        title: "Correct",
                        value: "\(Int(correct))",
                        icon: "checkmark.circle.fill",
                        color: AppConfig.Colors.success
                    )
                    StatCard(
                        title: "Incorrect",
                        value: "\(Int(incorrect))",
                        icon: "xmark.circle.fill",
                        color: AppConfig.Colors.alert
                    )
                }
                .padding(.horizontal)
                
                HStack(spacing: 16) {
                    StatCard(
                        title: "Total",
                        value: "\(Int(total))",
                        icon: "number.circle.fill",
                        color: AppConfig.Colors.accent
                    )
                    StatCard(
                        title: "Accuracy",
                        value: "\(percentage)%",
                        icon: "percent",
                        color: .blue
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Weekly Detail
    
    private var weeklyDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Weekly Trend")
            
            if viewModel.weeklyData.isEmpty {
                emptyStateView(message: "No weekly data available yet.")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.weeklyData) { item in
                        HStack {
                            Text(item.label)
                                .font(AppConfig.Fonts.bodyBold)
                                .foregroundColor(AppConfig.Colors.textPrimary)
                                .frame(width: 40, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(barColor(for: item.value))
                                        .frame(width: geo.size.width * (item.value / 100), height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(Int(item.value))%")
                                .font(AppConfig.Fonts.small)
                                .fontWeight(.bold)
                                .foregroundColor(barColor(for: item.value))
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Monthly Detail
    
    private var monthlyDetailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Monthly Overview")
            
            if viewModel.monthlyData.isEmpty {
                emptyStateView(message: "No monthly data available yet.")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.monthlyData) { item in
                        HStack {
                            Text(item.label)
                                .font(AppConfig.Fonts.bodyBold)
                                .foregroundColor(AppConfig.Colors.textPrimary)
                                .frame(width: 40, alignment: .leading)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(barColor(for: item.value))
                                        .frame(width: geo.size.width * (item.value / 100), height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(Int(item.value))%")
                                .font(AppConfig.Fonts.small)
                                .fontWeight(.bold)
                                .foregroundColor(barColor(for: item.value))
                                .frame(width: 45, alignment: .trailing)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.4))
            Text(message)
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private func barColor(for value: Double) -> Color {
        if value >= 70 { return AppConfig.Colors.success }
        if value >= 40 { return .orange }
        return AppConfig.Colors.alert
    }
    
    var iconForType: String {
        switch timeFrame {
        case .immediate: return "sun.max.fill"
        case .recent: return "calendar"
        case .remote: return "clock.arrow.circlepath"
        }
    }
}
