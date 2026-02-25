//
//  gamesCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct GamesCard: View {
    let game: gamesModel

    private var cardGradient: LinearGradient {
        switch game.screenName {
        case "WordAssociationGameView":
            return LinearGradient(
                colors: [Color(hex: "7B4FD9"), Color(hex: "B067E8")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case "MemoryGameView":
            return LinearGradient(
                colors: [Color(hex: "FF6B35"), Color(hex: "FFAA5C")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case "NumberBubblesGameView":
            return LinearGradient(
                colors: [Color(hex: "2CBFCE"), Color(hex: "3D8EE8")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case "DailyObjectsGameView":
            return LinearGradient(
                colors: [Color(hex: "3DBA7A"), Color(hex: "1DBBAA")],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(
                colors: [AppConfig.Colors.accent, AppConfig.Colors.accent.opacity(0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 76, height: 76)
                Image(systemName: game.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 14)

            // Name + description
            VStack(spacing: 5) {
                Text(game.name)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(game.description)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 34, alignment: .top)
            }
            .padding(.horizontal, 12)

            // Play pill
            HStack(spacing: 4) {
                Text("Play")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 18)
            .background(Color.white.opacity(0.25))
            .cornerRadius(20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(cardGradient)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 5)
    }
}
