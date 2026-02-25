//
//  OverallAnalyticsView.swift
//  recap
//
//  Created by Copilot on 25/02/26.
//

import SwiftUI
import Charts

struct OverallAnalyticsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppConfig.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // MARK: - Summary Header
                    overallSummarySection

                    // MARK: - Decline Alert
                    if let alert = viewModel.declineAlert, alert.detected {
                        declineAlertSection(alert: alert)
                    }

                    // MARK: - Today's Performance
                    todaySection

                    // MARK: - Weekly Trend
                    weeklySection

                    // MARK: - Monthly Overview
                    monthlySection

                    // MARK: - Engagement Heatmap
                    engagementSection

                    // MARK: - Category Breakdown
                    categorySection
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Analytics Overview")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overall Summary

    private var overallSummarySection: some View {
        VStack(spacing: 16) {
            if let summary = viewModel.overallSummary {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: min(summary.score / 100, 1.0))
                        .stroke(
                            scoreGradient(for: summary.score),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(summary.score))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppConfig.Colors.textPrimary)
                        Text("Overall")
                            .font(.caption)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
                .padding(.top, 20)

                Text("Last 30 Days Performance")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                // Stats grid
                HStack(spacing: 12) {
                    SummaryStatPill(
                        icon: "checkmark.circle.fill",
                        value: "\(summary.totalCorrect)",
                        label: "Correct",
                        color: AppConfig.Colors.success
                    )
                    SummaryStatPill(
                        icon: "questionmark.circle.fill",
                        value: "\(summary.totalQuestions)",
                        label: "Questions",
                        color: AppConfig.Colors.accent
                    )
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    SummaryStatPill(
                        icon: "flame.fill",
                        value: "\(summary.activeDaysLast7)/7",
                        label: "Active (7d)",
                        color: .orange
                    )
                    SummaryStatPill(
                        icon: "calendar",
                        value: "\(summary.activeDaysLast30)/30",
                        label: "Active (30d)",
                        color: .blue
                    )
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.4))
                    Text("No summary data available")
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }
                .padding(.vertical, 30)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Decline Alert

    private func declineAlertSection(alert: DeclineAlert) -> some View {
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

    // MARK: - Today

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            analyticsCardHeader(title: "Today's Performance", icon: "sun.max.fill")

            if viewModel.dailyData.isEmpty {
                emptyMiniState(message: "No data today")
            } else {
                DailyPerformanceChart(data: viewModel.dailyData)
                    .frame(height: 180)
                    .padding(.horizontal, 8)

                let correct = viewModel.dailyData.first(where: { $0.label == "Correct" })?.value ?? 0
                let incorrect = viewModel.dailyData.first(where: { $0.label == "Incorrect" })?.value ?? 0
                let total = correct + incorrect
                let pct = total > 0 ? Int((correct / total) * 100) : 0

                HStack(spacing: 16) {
                    MiniStat(label: "Correct", value: "\(Int(correct))", color: AppConfig.Colors.success)
                    MiniStat(label: "Incorrect", value: "\(Int(incorrect))", color: AppConfig.Colors.alert)
                    MiniStat(label: "Accuracy", value: "\(pct)%", color: .blue)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Weekly

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            analyticsCardHeader(title: "Weekly Trend", icon: "calendar")

            if viewModel.weeklyData.isEmpty {
                emptyMiniState(message: "No weekly data")
            } else {
                Chart(viewModel.weeklyData) { item in
                    AreaMark(
                        x: .value("Day", item.label),
                        y: .value("Score", item.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppConfig.Colors.accent.opacity(0.4), AppConfig.Colors.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", item.label),
                        y: .value("Score", item.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(AppConfig.Colors.accent)
                    .symbol {
                        Circle()
                            .fill(AppConfig.Colors.accent)
                            .frame(width: 6, height: 6)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
                .padding(.horizontal, 8)

                // Day-by-day scores
                HStack(spacing: 4) {
                    ForEach(viewModel.weeklyData) { item in
                        VStack(spacing: 2) {
                            Text("\(Int(item.value))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(barColor(for: item.value))
                            Text(item.label)
                                .font(.system(size: 10))
                                .foregroundColor(AppConfig.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Monthly

    private var monthlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            analyticsCardHeader(title: "Monthly Overview", icon: "clock.arrow.circlepath")

            if viewModel.monthlyData.isEmpty {
                emptyMiniState(message: "No monthly data")
            } else {
                Chart(viewModel.monthlyData) { item in
                    BarMark(
                        x: .value("Month", item.label),
                        y: .value("Score", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        Text("\(Int(item.value))%")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Engagement Heatmap

    private var engagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            analyticsCardHeader(title: "Engagement (Last 30 Days)", icon: "square.grid.3x3.fill")

            if viewModel.engagementHeatmap.isEmpty {
                emptyMiniState(message: "No engagement data")
            } else {
                // Calendar-like grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.engagementHeatmap) { day in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: day))
                            .frame(height: 28)
                            .overlay(
                                Text(dayNumber(from: day.date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(day.questionsAnswered > 0 ? .white : AppConfig.Colors.textSecondary.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 4)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 12, height: 12)
                        Text("Inactive")
                            .font(.caption2)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppConfig.Colors.accent.opacity(0.4))
                            .frame(width: 12, height: 12)
                        Text("Low")
                            .font(.caption2)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppConfig.Colors.accent.opacity(0.7))
                            .frame(width: 12, height: 12)
                        Text("Medium")
                            .font(.caption2)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppConfig.Colors.accent)
                            .frame(width: 12, height: 12)
                        Text("High")
                            .font(.caption2)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Category Breakdown

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            analyticsCardHeader(title: "Memory Category Breakdown", icon: "brain.head.profile")

            if viewModel.categoryBreakdown.isEmpty {
                emptyMiniState(message: "No category data")
            } else {
                ForEach(viewModel.categoryBreakdown) { cat in
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: categoryIcon(for: cat.category))
                                .foregroundColor(categoryColor(for: cat.category))
                                .font(.system(size: 16))
                            Text(cat.displayName)
                                .font(AppConfig.Fonts.bodyBold)
                                .foregroundColor(AppConfig.Colors.textPrimary)
                            Spacer()
                            Text("\(Int(cat.score))%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(barColor(for: cat.score))
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 10)
                                Capsule()
                                    .fill(barColor(for: cat.score))
                                    .frame(width: geo.size.width * min(cat.score / 100, 1.0), height: 10)
                            }
                        }
                        .frame(height: 10)

                        HStack {
                            Text("\(cat.correct) correct")
                                .font(.caption)
                                .foregroundColor(AppConfig.Colors.success)
                            Spacer()
                            Text("\(cat.incorrect) incorrect")
                                .font(.caption)
                                .foregroundColor(AppConfig.Colors.alert)
                            Spacer()
                            Text("\(cat.total) total")
                                .font(.caption)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(14)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func analyticsCardHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(AppConfig.Colors.accent)
                .font(.system(size: 16))
            Text(title)
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textPrimary)
            Spacer()
        }
    }

    private func emptyMiniState(message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    private func barColor(for value: Double) -> Color {
        if value >= 70 { return AppConfig.Colors.success }
        if value >= 40 { return .orange }
        return AppConfig.Colors.alert
    }

    private func scoreGradient(for score: Double) -> LinearGradient {
        if score >= 70 {
            return LinearGradient(colors: [AppConfig.Colors.success, AppConfig.Colors.accent], startPoint: .leading, endPoint: .trailing)
        } else if score >= 40 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [AppConfig.Colors.alert, .orange], startPoint: .leading, endPoint: .trailing)
        }
    }

    private func heatmapColor(for day: EngagementDay) -> Color {
        if day.questionsAnswered == 0 {
            return Color.gray.opacity(0.12)
        }
        let ratio = Double(day.questionsAnswered) / max(Double(day.totalQuestions), 1.0)
        if ratio >= 0.8 {
            return AppConfig.Colors.accent
        } else if ratio >= 0.5 {
            return AppConfig.Colors.accent.opacity(0.7)
        } else {
            return AppConfig.Colors.accent.opacity(0.4)
        }
    }

    private func dayNumber(from dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        if parts.count == 3, let day = Int(parts[2]) {
            return "\(day)"
        }
        return ""
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "immediateMemory": return "bolt.fill"
        case "recentMemory": return "clock.fill"
        case "remoteMemory": return "clock.arrow.circlepath"
        default: return "brain.head.profile"
        }
    }

    private func categoryColor(for category: String) -> Color {
        switch category {
        case "immediateMemory": return .orange
        case "recentMemory": return .blue
        case "remoteMemory": return .purple
        default: return AppConfig.Colors.accent
        }
    }
}

// MARK: - Subviews

struct SummaryStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppConfig.Colors.textPrimary)
                Text(label)
                    .font(.caption)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }
}

struct MiniStat: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppConfig.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}
