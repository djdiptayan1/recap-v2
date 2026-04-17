//
//  OverallAnalyticsView.swift
//  recap
//
//  Created by Copilot on 25/02/26.
//

import Charts
import SwiftUI

struct OverallAnalyticsView: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

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

                    // MARK: - Mood Trend
                    moodSection

                    // MARK: - Monthly Overview
                    monthlySection

                    // MARK: - Engagement Heatmap
                    engagementSection

                    // MARK: - Category Breakdown
                    categorySection

                    // MARK: - Memory Quiz History
                    memoryQuizSection

                    // MARK: - Game Insights
                    gameInsightsSection

                    // MARK: - Export PDF
                    Button(action: exportPDF) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Export Report as PDF")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppConfig.Colors.accent)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Analytics Overview")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Overall Summary

    private var overallSummarySection: some View {
        VStack(spacing: 16) {
            if let summary = viewModel.overallSummary {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                        .frame(width: 130, height: 130)

                    Circle()
                        .trim(from: 0, to: min(summary.score / 100, 1.0))
                        .stroke(
                            scoreGradient(for: summary.score),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(summary.score))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppConfig.Colors.textPrimary)
                        Text("Overall")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
                .padding(.top, 20)

                Text("Last 30 Days Performance")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                        color: AppConfig.Colors.accent.opacity(0.8)
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
//        .background(Color.white)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
//        .cornerRadius(20)
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
        .cornerRadius(AppConfig.UI.cornerRadius)
        .padding(.horizontal)
    }

    // MARK: - Today

    private var todaySection: some View {
        sectionCard(title: "Today's Performance", icon: "sun.max.fill") {
            if viewModel.dailyData.isEmpty {
                emptyMiniState(message: "No data today")
            } else {
                DailyPerformanceChart(data: viewModel.dailyData)
                    .frame(height: 180)
                    .padding(.horizontal, 8)

                let correct =
                    viewModel.dailyData.first(where: { $0.label == "Correct" })?.value ?? 0
                let incorrect =
                    viewModel.dailyData.first(where: { $0.label == "Incorrect" })?.value ?? 0
                let total = correct + incorrect
                let pct = total > 0 ? Int((correct / total) * 100) : 0

                HStack(spacing: 12) {
                    MiniStat(
                        label: "Correct", value: "\(Int(correct))", color: AppConfig.Colors.success)
                    MiniStat(
                        label: "Incorrect", value: "\(Int(incorrect))",
                        color: AppConfig.Colors.alert)
                    MiniStat(
                        label: "Accuracy", value: "\(pct)%",
                        color: pct >= 70
                            ? AppConfig.Colors.success
                            : (pct >= 40 ? .orange : AppConfig.Colors.alert))
                }
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Weekly

    private var weeklySection: some View {
        sectionCard(title: "Weekly Trend", icon: "calendar") {
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
                            colors: [
                                AppConfig.Colors.accent.opacity(0.4),
                                AppConfig.Colors.accent.opacity(0.0),
                            ],
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
    }

    private var gameInsightsSection: some View {
        sectionCard(title: "Game Insights", icon: "gamecontroller.fill") {
            if viewModel.gameBreakdown.isEmpty {
                emptyMiniState(message: "No game sessions yet")
            } else {
                if let overview = viewModel.gamesOverview {
                    HStack(spacing: 12) {
                        MiniStat(label: "7 Days", value: "\(overview.sessionsLast7Days)", color: AppConfig.Colors.accent)
                        MiniStat(label: "Accuracy", value: "\(Int(overview.averageAccuracy))%", color: AppConfig.Colors.success)
                        MiniStat(
                            label: "Favorite",
                            value: RecapGameType(rawValue: overview.favoriteGame ?? "")?.displayName ?? "None",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 8)
                }

                VStack(spacing: 10) {
                    ForEach(viewModel.gameBreakdown.prefix(3)) { item in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.displayName)
                                    .font(AppConfig.Fonts.bodyBold)
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                Text("\(item.sessions) sessions • best \(item.bestScore)")
                                    .font(AppConfig.Fonts.small)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                            Spacer()
                            Text("\(Int(item.averageAccuracy))%")
                                .font(AppConfig.Fonts.headline)
                                .foregroundColor(AppConfig.Colors.accent)
                        }
                        .padding(14)
                        .background(AppConfig.Colors.card.opacity(0.9))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    private var moodSection: some View {
        sectionCard(title: "Mood Trend", icon: "face.smiling") {
            if let moodSummary = viewModel.moodSummary, !moodSummary.weekly.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    if let latest = moodSummary.latest {
                        let palette = latest.moodKey.palette

                        HStack(spacing: 12) {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            palette.glow.opacity(0.95),
                                            palette.primary.opacity(0.8),
                                            palette.secondary.opacity(0.45),
                                        ],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 22
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(.white.opacity(0.82), lineWidth: 1))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Latest: \(latest.label)")
                                    .font(AppConfig.Fonts.bodyBold)
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                Text(latest.shortLoggedTime)
                                    .font(AppConfig.Fonts.small)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }

                            Spacer()

                            if let average = moodSummary.averageScoreLast7 {
                                Text(String(format: "%.1f / 4", average))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.accent)
                            }
                        }
                        .padding(.horizontal, 8)
                    }

                    Chart(moodSummary.weekly) { item in
                        if let score = item.score {
                            AreaMark(
                                x: .value("Day", item.label),
                                y: .value("Mood", score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        moodColor(for: score).opacity(0.32),
                                        moodColor(for: score).opacity(0.02),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            LineMark(
                                x: .value("Day", item.label),
                                y: .value("Mood", score)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(moodColor(for: score))
                            .symbol {
                                Circle()
                                    .fill(moodColor(for: score))
                                    .frame(width: 7, height: 7)
                            }
                        }
                    }
                    .chartYScale(domain: 0...4)
                    .chartYAxis {
                        AxisMarks(values: [0, 1, 2, 3, 4]) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let score = value.as(Double.self) {
                                    Text(moodLabel(for: score))
                                }
                            }
                        }
                    }
                    .frame(height: 170)
                    .padding(.horizontal, 8)

                    HStack(spacing: 8) {
                        ForEach(moodSummary.weekly) { item in
                            VStack(spacing: 4) {
                                Text(item.moodLabel)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                                    .lineLimit(1)
                                Text(item.label)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                emptyMiniState(message: "No mood check-ins yet")
            }
        }
    }

    // MARK: - Monthly

    private var monthlySection: some View {
        sectionCard(title: "Monthly Overview", icon: "clock.arrow.circlepath") {
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
                            colors: [
                                AppConfig.Colors.accent, AppConfig.Colors.accent.opacity(0.6),
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        Text("\(Int(item.value))%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Engagement Heatmap

    private var engagementSection: some View {
        sectionCard(title: "Engagement (Last 30 Days)", icon: "square.grid.3x3.fill") {
            if viewModel.engagementHeatmap.isEmpty {
                emptyMiniState(message: "No engagement data")
            } else {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.engagementHeatmap) { day in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: day))
                            .frame(height: 28)
                            .overlay(
                                Text(dayNumber(from: day.date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(
                                        day.questionsAnswered > 0
                                            ? .white : AppConfig.Colors.textSecondary.opacity(0.6))
                            )
                    }
                }
                .padding(.horizontal, 4)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: Color.gray.opacity(0.15), label: "Inactive")
                    legendItem(color: AppConfig.Colors.accent.opacity(0.4), label: "Low")
                    legendItem(color: AppConfig.Colors.accent.opacity(0.7), label: "Medium")
                    legendItem(color: AppConfig.Colors.accent, label: "High")
                }
            }
        }
    }

    // MARK: - Category Breakdown

    private var categorySection: some View {
        sectionCard(title: "Memory Category Breakdown", icon: "brain.head.profile") {
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
                                    .fill(barColor(for: cat.score).gradient)
                                    .frame(
                                        width: geo.size.width * min(cat.score / 100, 1.0),
                                        height: 10)
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
    }

    // MARK: - Memory Quiz History

    private var memoryQuizSection: some View {
        sectionCard(title: "Memory Quiz Reports", icon: "brain") {
            if viewModel.memoryReports.isEmpty {
                emptyMiniState(message: "No quiz reports available")
            } else {
                // Show latest report summary
                if let latest = viewModel.memoryReports.first {
                    VStack(spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(latest.swiftColor.opacity(0.12))
                                    .frame(width: 50, height: 50)
                                Image(systemName: latest.safeIcon)
                                    .font(.system(size: 22))
                                    .foregroundColor(latest.swiftColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Latest: \(latest.safeStatus)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                Text(latest.formattedDate)
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }

                            Spacer()

                            VStack(spacing: 2) {
                                Text("\(latest.safeTotalScore)/\(latest.safeTotalQuestions)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(latest.swiftColor)
                                Text("Score")
                                    .font(.caption2)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                        }

                        if let pct = latest.overallPercentage {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(latest.swiftColor.gradient)
                                        .frame(
                                            width: geo.size.width * min(pct / 100, 1.0), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(16)
                    .background(latest.swiftColor.opacity(0.05))
                    .cornerRadius(14)
                }

                // History list (show up to 5 recent)
                if viewModel.memoryReports.count > 1 {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(viewModel.memoryReports.prefix(5).dropFirst().enumerated()),
                            id: \.element.id
                        ) { index, report in
                            if index > 0 {
                                Divider().padding(.leading, 50)
                            }

                            HStack(spacing: 12) {
                                Image(systemName: report.safeIcon)
                                    .font(.system(size: 16))
                                    .foregroundColor(report.swiftColor)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(report.safeStatus)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(AppConfig.Colors.textPrimary)
                                    Text(report.formattedDate)
                                        .font(.system(size: 11, design: .rounded))
                                        .foregroundColor(AppConfig.Colors.textSecondary)
                                }

                                Spacer()

                                Text("\(report.safeTotalScore)/\(report.safeTotalQuestions)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(report.swiftColor)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                }

                if viewModel.memoryReports.count > 5 {
                    NavigationLink(
                        destination: MemoryQuizHistoryListView(reports: viewModel.memoryReports)
                    ) {
                        HStack {
                            Text("View All Reports")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(AppConfig.Colors.accent)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppConfig.Colors.accent)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Reusable Section Card

    private func sectionCard<Content: View>(
        title: String, icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
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
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
//        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    // MARK: - PDF Export

    private func exportPDF() {
        let renderer = PDFReportRenderer(viewModel: viewModel)
        if let url = renderer.renderPDF() {
            pdfURL = url
            showShareSheet = true
        }
    }

    // MARK: - Helpers

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppConfig.Colors.textSecondary)
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
            return LinearGradient(
                colors: [AppConfig.Colors.success, AppConfig.Colors.accent], startPoint: .leading,
                endPoint: .trailing)
        } else if score >= 40 {
            return LinearGradient(
                colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(
                colors: [AppConfig.Colors.alert, .orange], startPoint: .leading, endPoint: .trailing
            )
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
        case "recentMemory": return AppConfig.Colors.accent
        case "remoteMemory": return AppConfig.Colors.success
        default: return AppConfig.Colors.accent
        }
    }

    private func moodColor(for score: Double) -> Color {
        switch score {
        case ..<0.5:
            return DailyMoodKey.veryUnpleasant.palette.primary
        case ..<1.5:
            return DailyMoodKey.unpleasant.palette.primary
        case ..<2.5:
            return DailyMoodKey.neutral.palette.primary
        case ..<3.5:
            return DailyMoodKey.pleasant.palette.primary
        default:
            return DailyMoodKey.veryPleasant.palette.primary
        }
    }

    private func moodLabel(for score: Double) -> String {
        switch score {
        case ..<0.5: return "Very Low"
        case ..<1.5: return "Low"
        case ..<2.5: return "Neutral"
        case ..<3.5: return "Good"
        default: return "High"
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Renderer

class PDFReportRenderer {
    let viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
    }

    func renderPDF() -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - 2 * margin

        let pdfMetaData = [
            kCGPDFContextCreator: "Recap",
            kCGPDFContextAuthor: "Recap App",
            kCGPDFContextTitle: "Cognitive Analytics Report",
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        let dateStr = dateFormatter.string(from: Date())

        let data = renderer.pdfData { context in
            context.beginPage()
            var yPos: CGFloat = margin

            // Title
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label,
            ]
            let title = "Cognitive Analytics Report"
            title.draw(at: CGPoint(x: margin, y: yPos), withAttributes: titleAttr)
            yPos += 36

            // Date
            let dateAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            "Generated: \(dateStr)".draw(at: CGPoint(x: margin, y: yPos), withAttributes: dateAttr)
            yPos += 30

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPos))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPos))
            UIColor.separator.setStroke()
            dividerPath.lineWidth = 1
            dividerPath.stroke()
            yPos += 20

            // Helper closures
            let sectionTitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.label,
            ]
            let bodyAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.label,
            ]
            let boldBodyAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                .foregroundColor: UIColor.label,
            ]

            func checkPage(_ needed: CGFloat) {
                if yPos + needed > pageHeight - margin {
                    context.beginPage()
                    yPos = margin
                }
            }

            // Overall Summary
            if let summary = viewModel.overallSummary {
                checkPage(80)
                "Overall Summary (Last 30 Days)".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
                yPos += 28
                "Overall Score: \(Int(summary.score))%".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: boldBodyAttr)
                yPos += 20
                "Total Correct: \(summary.totalCorrect)  |  Total Questions: \(summary.totalQuestions)"
                    .draw(at: CGPoint(x: margin, y: yPos), withAttributes: bodyAttr)
                yPos += 20
                "Active Days (7d): \(summary.activeDaysLast7)/7  |  Active Days (30d): \(summary.activeDaysLast30)/30"
                    .draw(at: CGPoint(x: margin, y: yPos), withAttributes: bodyAttr)
                yPos += 30
            }

            // Decline Alert
            if let alert = viewModel.declineAlert, alert.detected {
                checkPage(60)
                "⚠️ Decline Alert".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
                yPos += 28
                let alertStr = NSString(string: alert.message)
                let alertRect = CGRect(x: margin, y: yPos, width: contentWidth, height: 60)
                alertStr.draw(in: alertRect, withAttributes: bodyAttr)
                yPos += 50
                let scoresStr = alert.weeklyScores.enumerated().map {
                    "W\($0.offset + 1): \(Int($0.element))%"
                }.joined(separator: "  |  ")
                scoresStr.draw(at: CGPoint(x: margin, y: yPos), withAttributes: boldBodyAttr)
                yPos += 30
            }

            // Daily
            checkPage(60)
            "Today's Performance".draw(
                at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
            yPos += 28
            let correct = viewModel.dailyData.first(where: { $0.label == "Correct" })?.value ?? 0
            let incorrect =
                viewModel.dailyData.first(where: { $0.label == "Incorrect" })?.value ?? 0
            let total = correct + incorrect
            let pct = total > 0 ? Int((correct / total) * 100) : 0
            "Correct: \(Int(correct))  |  Incorrect: \(Int(incorrect))  |  Total: \(Int(total))  |  Accuracy: \(pct)%"
                .draw(at: CGPoint(x: margin, y: yPos), withAttributes: bodyAttr)
            yPos += 30

            // Weekly
            if !viewModel.weeklyData.isEmpty {
                checkPage(60)
                "Weekly Trend".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
                yPos += 28
                for item in viewModel.weeklyData {
                    checkPage(20)
                    "\(item.label):  \(Int(item.value))%".draw(
                        at: CGPoint(x: margin + 10, y: yPos), withAttributes: bodyAttr)
                    yPos += 18
                }
                yPos += 12
            }

            // Monthly
            if !viewModel.monthlyData.isEmpty {
                checkPage(60)
                "Monthly Overview".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
                yPos += 28
                for item in viewModel.monthlyData {
                    checkPage(20)
                    "\(item.label):  \(Int(item.value))%".draw(
                        at: CGPoint(x: margin + 10, y: yPos), withAttributes: bodyAttr)
                    yPos += 18
                }
                yPos += 12
            }

            // Category Breakdown
            if !viewModel.categoryBreakdown.isEmpty {
                checkPage(60)
                "Memory Category Breakdown".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
                yPos += 28
                for cat in viewModel.categoryBreakdown {
                    checkPage(20)
                    "\(cat.displayName):  \(Int(cat.score))%  (\(cat.correct) correct / \(cat.total) total)"
                        .draw(at: CGPoint(x: margin + 10, y: yPos), withAttributes: bodyAttr)
                    yPos += 18
                }
                yPos += 12
            }

            // Memory Quiz Reports
            if !viewModel.memoryReports.isEmpty {
                checkPage(60)
                "Memory Quiz Reports".draw(
                    at: CGPoint(x: margin, y: yPos), withAttributes: sectionTitleAttr)
                yPos += 28
                for report in viewModel.memoryReports.prefix(10) {
                    checkPage(22)
                    let pctStr =
                        report.overallPercentage != nil
                        ? " (\(Int(report.overallPercentage!))%)" : ""
                    "\(report.safeStatus) — \(report.safeTotalScore)/\(report.safeTotalQuestions)\(pctStr)  —  \(report.formattedDate)"
                        .draw(at: CGPoint(x: margin + 10, y: yPos), withAttributes: bodyAttr)
                    yPos += 20
                }
                yPos += 12
            }

            // Footer
            checkPage(30)
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.tertiaryLabel,
            ]
            "Report generated by Recap App — \(dateStr)".draw(
                at: CGPoint(x: margin, y: pageHeight - margin), withAttributes: footerAttr)
        }

        // Save to temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Recap_Analytics_Report_\(dateStr.replacingOccurrences(of: " ", with: "_")).pdf")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
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
