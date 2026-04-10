//
//  MemoryQuizDetailView.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import SwiftUI

struct MemoryQuizDetailView: View {
    let report: MemoryReport
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {

                // MARK: - 1. Hero Header
                VStack(spacing: 16) {
                    // Icon Ring
                    ZStack {
                        Circle()
                            .strokeBorder(report.swiftColor.opacity(0.2), lineWidth: 3)
                            .background(Circle().fill(report.swiftColor.opacity(0.1)))
                            .frame(width: 100, height: 100)

                        Image(systemName: report.safeIcon)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(report.swiftColor)
                    }
                    .shadow(color: report.swiftColor.opacity(0.2), radius: 10, x: 0, y: 5)

                    VStack(spacing: 4) {
                        Text(report.safeStatus)
                            .font(AppConfig.Fonts.titleLarge)
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text(report.formattedDate)
                            .font(AppConfig.Fonts.body)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }
                }
                .padding(.top, 20)

                // MARK: - 2. Key Stats Grid
                HStack(spacing: 16) {
                    StatCard(
                        title: "Percentage",
                        value: "\(Int(report.overallPercentage ?? 0.0))%",
                        icon: "percent",
                        color: report.swiftColor
                    )

                    StatCard(
                        title: "Total Score",
                        value: "\(report.safeTotalScore)/\(report.safeTotalQuestions)",
                        icon: "checkmark.circle.fill",
                        color: report.swiftColor
                    )
                }
                .padding(.horizontal)

                // MARK: - 3. Detailed Analysis (Progress Bars)
                if let typeScores = report.typeScores, !typeScores.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Detailed Analysis")

                        VStack(spacing: 16) {
                            ForEach(typeScores, id: \.memoryType) { score in
                                // FIX: We pass the raw values here instead of the whole object
                                ScoreProgressRow(
                                    label: (score.memoryType ?? "General").capitalized,
                                    correct: score.correct ?? 0,
                                    total: score.total ?? 0,
                                    tint: report.swiftColor
                                )
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                }

                // MARK: - 4. Recommendations
                if let recommendations = report.recommendations, !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Recommendations")

                        VStack(spacing: 12) {
                            ForEach(recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 18))
                                        .padding(.top, 2)

                                    Text(recommendation)
                                        .font(AppConfig.Fonts.body)
                                        .foregroundColor(AppConfig.Colors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(4)

                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.orange.opacity(0.08))  // Subtle tint
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews for Cleanliness

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
            }
        }
        .padding(16)
        .glassEffect(.regular, in:.rect(cornerRadius: AppConfig.UI.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// FIX: This struct now accepts simple types (Int, String) instead of the missing MemoryTypeScore
struct ScoreProgressRow: View {
    let label: String
    let correct: Int
    let total: Int
    let tint: Color

    var percent: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(AppConfig.Fonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                Spacer()

                Text("\(correct)/\(total)")
                    .font(AppConfig.Fonts.small)
                    .fontWeight(.bold)
                    .foregroundColor(tint)
            }

            // Custom Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    Capsule()
                        .fill(tint)
                        .frame(width: geo.size.width * percent, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
