import SwiftUI

struct MoodInsightsCard: View {
    let patientId: String
    let patientName: String
    @StateObject private var viewModel = DailyMoodViewModel()

    private var activePalette: MoodPalette {
        viewModel.todayEntry?.moodKey.palette ?? DailyMoodKey.neutral.palette
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Mood")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text("A quick check-in from \(patientName.split(separator: " ").first ?? "")")
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppConfig.Colors.accent)
                }
            }

            if let todayEntry = viewModel.todayEntry {
                let palette = todayEntry.moodKey.palette

                HStack(spacing: 14) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    palette.glow.opacity(0.95),
                                    palette.primary.opacity(0.82),
                                    palette.secondary.opacity(0.45),
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: 26
                            )
                        )
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 1)
                        )
                        .shadow(color: palette.primary.opacity(0.28), radius: 10, x: 0, y: 5)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(todayEntry.label)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text("Logged at \(todayEntry.shortLoggedTime)")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                    }

                    Spacer()
                }
                .padding(16)
            } else {
                Text("No mood has been logged today yet.")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .padding(.vertical, 8)
            }

//            if !viewModel.history.isEmpty {
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("Last 7 Days")
//                        .font(AppConfig.Fonts.bodyBold)
//                        .foregroundColor(AppConfig.Colors.textPrimary)
//
//                    HStack(spacing: 8) {
//                        ForEach(Array(viewModel.history.prefix(7).reversed()), id: \.id) { entry in
//                            VStack(spacing: 6) {
//                                Circle()
//                                    .fill(entry.moodKey.palette.primary)
//                                    .frame(width: 14, height: 14)
//                                Text(shortDayLabel(from: entry.dateKey))
//                                    .font(.system(size: 11, weight: .medium, design: .rounded))
//                                    .foregroundColor(AppConfig.Colors.textSecondary)
//                            }
//                            .frame(maxWidth: .infinity)
//                        }
//                    }
//                }
//            }
        }
        .padding(18)
        .glassEffect(
            .clear.tint(activePalette.primary.opacity(0.6)),
            in: .rect(cornerRadius: AppConfig.UI.cornerRadius)
        )
        .task(id: patientId) {
            await viewModel.refresh(patientId: patientId)
        }
    }

    private func shortDayLabel(from dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateKey) else { return "--" }

        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "E"
        return labelFormatter.string(from: date)
    }
}

#Preview {
    MoodInsightsCard(patientId: "preview", patientName: "Alex")
        .padding()
}
