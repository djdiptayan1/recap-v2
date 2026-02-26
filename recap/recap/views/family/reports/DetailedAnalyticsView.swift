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
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppConfig.Colors.accent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: iconForType)
                                .font(.system(size: 36))
                                .foregroundColor(AppConfig.Colors.accent)
                        }
                        
                        Text("\(timeFrame.rawValue) Report")
                            .font(AppConfig.Fonts.titleMedium)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                        
                        Text("Detailed breakdown of cognitive performance")
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Decline Alert
                    if let alert = viewModel.declineAlert, alert.detected {
                        declineAlertCard(alert: alert)
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
    
    // MARK: - Decline Alert Card
    
    private func declineAlertCard(alert: DeclineAlert) -> some View {
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
            
            HStack(spacing: 8) {
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
    
    // MARK: - Daily Detail
    
    private var dailyDetailSection: some View {
        VStack(spacing: 20) {
            // Chart card
            // analyticsCard(title: "Today's Performance", icon: "sun.max.fill") {
            //     if viewModel.dailyData.isEmpty {
            //         emptyStateView(message: "No questions answered today yet.")
            //     } else {
            //         DailyPerformanceChart(data: viewModel.dailyData)
            //             .frame(height: 200)
            //             .padding(.horizontal, 8)
            //     }
            // }
            
            // Stats
            if !viewModel.dailyData.isEmpty {
                let correct = viewModel.dailyData.first(where: { $0.label == "Correct" })?.value ?? 0
                let incorrect = viewModel.dailyData.first(where: { $0.label == "Incorrect" })?.value ?? 0
                let total = correct + incorrect
                let percentage = total > 0 ? Int((correct / total) * 100) : 0
                
                analyticsCard(title: "Key Metrics", icon: "chart.bar.fill") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DetailStatTile(icon: "checkmark.circle.fill", title: "Correct", value: "\(Int(correct))", color: AppConfig.Colors.success)
                        DetailStatTile(icon: "xmark.circle.fill", title: "Incorrect", value: "\(Int(incorrect))", color: AppConfig.Colors.alert)
                        DetailStatTile(icon: "number.circle.fill", title: "Total", value: "\(Int(total))", color: AppConfig.Colors.accent)
                        DetailStatTile(icon: "percent", title: "Accuracy", value: "\(percentage)%", color: percentage >= 70 ? AppConfig.Colors.success : (percentage >= 40 ? .orange : AppConfig.Colors.alert))
                    }
                }
            }
        }
    }
    
    // MARK: - Weekly Detail
    
    private var weeklyDetailSection: some View {
        VStack(spacing: 20) {
            // Chart card
            // analyticsCard(title: "Weekly Trend", icon: "calendar") {
            //     if viewModel.weeklyData.isEmpty {
            //         emptyStateView(message: "No weekly data available yet.")
            //     } else {
            //         Chart(viewModel.weeklyData) { item in
            //             AreaMark(
            //                 x: .value("Day", item.label),
            //                 y: .value("Score", item.value)
            //             )
            //             .interpolationMethod(.catmullRom)
            //             .foregroundStyle(
            //                 LinearGradient(
            //                     colors: [AppConfig.Colors.accent.opacity(0.4), AppConfig.Colors.accent.opacity(0.0)],
            //                     startPoint: .top,
            //                     endPoint: .bottom
            //                 )
            //             )
                        
            //             LineMark(
            //                 x: .value("Day", item.label),
            //                 y: .value("Score", item.value)
            //             )
            //             .interpolationMethod(.catmullRom)
            //             .foregroundStyle(AppConfig.Colors.accent)
            //             .symbol {
            //                 Circle()
            //                     .fill(AppConfig.Colors.accent)
            //                     .frame(width: 6, height: 6)
            //             }
            //         }
            //         .chartYScale(domain: 0...100)
            //         .frame(height: 180)
            //         .padding(.horizontal, 8)
            //     }
            // }
            
            // Day breakdown
            if !viewModel.weeklyData.isEmpty {
                analyticsCard(title: "Daily Scores", icon: "list.bullet") {
                    VStack(spacing: 10) {
                        ForEach(viewModel.weeklyData) { item in
                            HStack(spacing: 12) {
                                Text(item.label)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                    .frame(width: 40, alignment: .leading)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.12))
                                            .frame(height: 10)
                                        
                                        Capsule()
                                            .fill(barColor(for: item.value).gradient)
                                            .frame(width: max(geo.size.width * (item.value / 100), 0), height: 10)
                                    }
                                }
                                .frame(height: 10)
                                
                                Text("\(Int(item.value))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(barColor(for: item.value))
                                    .frame(width: 45, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Monthly Detail
    
    private var monthlyDetailSection: some View {
        VStack(spacing: 20) {
            // Chart card
            // analyticsCard(title: "Monthly Overview", icon: "clock.arrow.circlepath") {
            //     if viewModel.monthlyData.isEmpty {
            //         emptyStateView(message: "No monthly data available yet.")
            //     } else {
            //         Chart(viewModel.monthlyData) { item in
            //             BarMark(
            //                 x: .value("Month", item.label),
            //                 y: .value("Score", item.value)
            //             )
            //             .foregroundStyle(
            //                 LinearGradient(
            //                     colors: [AppConfig.Colors.accent, AppConfig.Colors.accent.opacity(0.6)],
            //                     startPoint: .bottom,
            //                     endPoint: .top
            //                 )
            //             )
            //             .cornerRadius(8)
            //             .annotation(position: .top) {
            //                 Text("\(Int(item.value))%")
            //                     .font(.system(size: 11, weight: .bold, design: .rounded))
            //                     .foregroundColor(AppConfig.Colors.textSecondary)
            //             }
            //         }
            //         .chartYScale(domain: 0...100)
            //         .frame(height: 180)
            //         .padding(.horizontal, 8)
            //     }
            // }
            
            // Month breakdown
            if !viewModel.monthlyData.isEmpty {
                analyticsCard(title: "Monthly Scores", icon: "list.bullet") {
                    VStack(spacing: 10) {
                        ForEach(viewModel.monthlyData) { item in
                            HStack(spacing: 12) {
                                Text(item.label)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                    .frame(width: 40, alignment: .leading)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.gray.opacity(0.12))
                                            .frame(height: 10)
                                        
                                        Capsule()
                                            .fill(barColor(for: item.value).gradient)
                                            .frame(width: max(geo.size.width * (item.value / 100), 0), height: 10)
                                    }
                                }
                                .frame(height: 10)
                                
                                Text("\(Int(item.value))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(barColor(for: item.value))
                                    .frame(width: 45, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Reusable Card Wrapper
    
    private func analyticsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppConfig.Colors.accent)
                    .font(.system(size: 16))
                Text(title)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                Spacer()
            }
            
            content()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
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

// MARK: - Detail Stat Tile

struct DetailStatTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppConfig.Colors.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .cornerRadius(16)
    }
}
