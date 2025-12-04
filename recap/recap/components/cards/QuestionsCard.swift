//
//  QuestionsCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct QuestionsCard: View {
    var body: some View {
        NavigationLink(destination: ArticlesView()) {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
    //                    Image(systemName: "book.pages.fill")
    //                        .foregroundColor(AppConfig.Colors.accent)
    //                        .font(.system(size: 16))
                        
                        Text("Daily Questions")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                }
                .padding(AppConfig.UI.padding)
                
                Divider()
                    .background(AppConfig.Colors.stroke)
                    .padding(.horizontal, AppConfig.UI.padding)
                
                HStack(alignment: .top, spacing: 20) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keep your memory sharp")
                            .font(AppConfig.Fonts.bodyBold)
                            .foregroundColor(AppConfig.Colors.textPrimary)
                        
                        Text("A little effort each day keeps the memories strong.")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(4)
                        
    //                    HStack(spacing: 6) {
    //                        Text("Open Library")
    //                            .font(.system(size: 12, weight: .bold))
    //                        Image(systemName: "arrow.right")
    //                            .font(.system(size: 10, weight: .bold))
    //                    }
    //                    .padding(.vertical, 8)
    //                    .padding(.horizontal, 12)
    //                    .background(AppConfig.Colors.accent.opacity(0.1))
    //                    .foregroundColor(AppConfig.Colors.accent)
    //                    .cornerRadius(20)
    //                    .padding(.top, 4)
                    }
//                        Spacer()
                        Image("oldMan")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
//                            .clipShape(Circle())
//                            .overlay(
//                                Circle()
//                                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
//                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
//                            .padding(.horizontal, 20)
                }
                .padding(20)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
        QuestionsCard()
}
