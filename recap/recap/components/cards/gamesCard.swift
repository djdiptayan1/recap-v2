//
//  gamesCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct GamesCard: View {
    let game: gamesModel
    
    private var themeColor: Color {
        switch game.imageName {
        case "geoGusser": return Color.blue
        case "MemoryMatch": return Color.orange
        case "brain.head.profile": return Color.purple
        default: return AppConfig.Colors.accent
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack {
                Circle()
                    .fill(themeColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if game.imageName.contains(".") {
                    Image(systemName: game.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(themeColor)
                } else {
                    Image(game.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            VStack(spacing: 4) {
                Text(game.name)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                
                Text(game.description)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 36, alignment: .top)
                
                Spacer().frame(height: 12)
                
//                // "Play" Action Pill
//                HStack(spacing: 4) {
//                    Text("Play")
//                        .font(.system(size: 13, weight: .bold))
//                    Image(systemName: "play.fill")
//                        .font(.system(size: 10))
//                }
//                .foregroundColor(.white)
//                .padding(.vertical, 8)
//                .padding(.horizontal, 20)
//                .background(themeColor)
//                .cornerRadius(20)
//                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
//        .background(Color.white)
        .glassEffect(.clear, in: .rect)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
//        .overlay(
//            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
//                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
//        )
    }
}
