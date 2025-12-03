//
//  GameObjectCard.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct GameObjectCard: View {
    let object: DailyObject
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(object.color.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: object.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .foregroundColor(object.color)
            }
            
            Text(object.name)
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(minWidth: 100, minHeight: 140)
        .background(isSelected ? object.color.opacity(0.1) : Color.white)
        .cornerRadius(AppConfig.UI.cornerRadius)
        // Selection State Borders
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                .stroke(isSelected ? object.color : AppConfig.Colors.stroke, lineWidth: isSelected ? 3 : 1)
        )
        .shadow(color: isSelected ? object.color.opacity(0.2) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
