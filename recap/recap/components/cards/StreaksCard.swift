//
//  StreaksCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct StreaksCard: View {
    @State private var maxStreak = 0
    @State private var currentStreak = 0
    @State private var activeDays = 0

    private let flameGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationLink(destination: StreaksView(verifiedUserDocID: "DUMMYY")) {
            VStack(spacing: 0) {
                HStack {
                    Text("Daily Insight")
                        .font(AppConfig.Fonts.titleMedium)
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
                        //                    icon: "trophy.fill",
                        color: Color.yellow,
                        value: "\(maxStreak)",
                        label: "Max Streak"
                    )

                    Rectangle()
                        .fill(AppConfig.Colors.stroke)
                        .frame(width: 1, height: 40)

                    SingleStatColumn(
                        //                    icon: "flame.fill",
                        color: Color.orange,
                        value: "\(currentStreak)",
                        label: "Current"
                    )

                    Rectangle()
                        .fill(AppConfig.Colors.stroke)
                        .frame(width: 1, height: 40)

                    SingleStatColumn(
                        //                    icon: "calendar.badge.clock",
                        color: AppConfig.Colors.accent,
                        value: "\(activeDays)",
                        label: "Active Days"
                    )
                }
                .padding(.vertical, 20)
            }
            //        .background(Color.white)
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
                loadStreakData()
            }
        }
    }

    private func loadStreakData() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "maxStreak") == nil {
            maxStreak = 12
            currentStreak = 5
            activeDays = 45
        } else {
            maxStreak = defaults.integer(forKey: "maxStreak")
            currentStreak = defaults.integer(forKey: "currentStreak")
            activeDays = defaults.integer(forKey: "activeDays")
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
