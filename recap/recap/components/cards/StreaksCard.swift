//
//  StreaksCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct StreaksCard: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = StreakViewModel(documentID: "")

    private let flameGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        // Use patientDocumentID for Streaks data
        let documentID = KeychainManager.shared.getString(key: .patientDocumentID) ?? appState.currentUser?.id ?? ""
        
        NavigationLink(destination: StreaksView(documentID: documentID)) {
            VStack(spacing: 0) {
                HStack {
                    Text("Daily Insight")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                }
                .padding(AppConfig.UI.padding)

                Divider()
                    .background(AppConfig.Colors.stroke)

                HStack(spacing: 0) {
                    SingleStatColumn(
                        color: Color.yellow,
                        value: "\(viewModel.maxStreak)",
                        label: "Max Streak"
                    )

                    Rectangle()
                        .fill(AppConfig.Colors.stroke)
                        .frame(width: 1, height: 40)

                    SingleStatColumn(
                        color: Color.orange,
                        value: "\(viewModel.currentStreak)",
                        label: "Current"
                    )

                    Rectangle()
                        .fill(AppConfig.Colors.stroke)
                        .frame(width: 1, height: 40)

                    SingleStatColumn(
                        color: AppConfig.Colors.accent,
                        value: "\(viewModel.activeDays)",
                        label: "Active Days"
                    )
                }
                .padding(.vertical, 20)
            }
            .glassEffect(.clear, in: .rect)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: AppConfig.UI.cardShadowRadius,
                x: 0,
                y: AppConfig.UI.cardShadowOffsetY
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )
            .onAppear {
                if !documentID.isEmpty {
                    viewModel.updateDocumentID(documentID)
                    Task {
                        await viewModel.fetchStreakStats()
                    }
                }
            }
            .onChange(of: documentID) { newID in
                if !newID.isEmpty {
                    viewModel.updateDocumentID(newID)
                    Task {
                        await viewModel.fetchStreakStats()
                    }
                }
            }
        }
    }
}

struct SingleStatColumn: View {
//    let icon: String
    let color: Color
    let value: String
    let label: String


    var body: some View {
        VStack(spacing: 8) {
//            ZStack {
//                Circle()
//                    .fill(color.opacity(0.1))
//                    .frame(width: 32, height: 32)
//
//                Image(systemName: icon)
//                    .font(.system(size: 14, weight: .bold))
//                    .foregroundColor(color)
//            }

            VStack(spacing: 2) {
                Text(value)
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                Text(label)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StreaksCard()
}
