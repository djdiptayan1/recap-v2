//
//  gamesCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//
//
import SwiftUI

struct GamesCard: View {
    let game: gamesModel

    private var cardTintColor: Color {
        switch game.screenName {
        case "WordAssociationGameView":
            return Color(hex: "7B4FD9")
        case "MemoryGameView":
            return Color(hex: "FF6B35")
        case "NumberBubblesGameView":
            return Color(hex: "2CBFCE")
        case "DailyObjectsGameView":
            return Color(hex: "3DBA7A")
        default:
            return AppConfig.Colors.accent
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Icon with soft glow
            ZStack {
                // Subtle glow behind the icon
//                Circle()
//                    .fill(cardTintColor.opacity(0.25))
//                    .frame(width: 70, height: 70)
//                    .blur(radius: 16)

                // Inner glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: game.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(.white)
                            .shadow(color: cardTintColor.opacity(0.5), radius: 4, y: 2)
                    )
            }
            .padding(.top, 20)

            // Name + description
            VStack(spacing: 6) {
                Text(game.name)
                    .font(AppConfig.Fonts.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(game.description)
                    .font(AppConfig.Fonts.small)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .glassEffect(
            .regular.tint(cardTintColor).interactive(),
            in: .rect(cornerRadius: AppConfig.UI.cornerRadius)
        )
    }
}
