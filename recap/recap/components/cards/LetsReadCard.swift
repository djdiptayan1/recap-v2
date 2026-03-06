//
//  LetsReadCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct LetsReadCard: View {
    var body: some View {
        NavigationLink(destination: ArticlesView()) {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        //                    Image(systemName: "book.pages.fill")
                        //                        .foregroundColor(AppConfig.Colors.accent)
                        //                        .font(.system(size: 16))

                        Text("Let's Read")
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
                        Text("Expand your mind")
                            .font(AppConfig.Fonts.bodyBold)
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text("Each word you read strengthens your journey. Keep exploring!")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image("BigShoesTorso")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, AppConfig.UI.padding)
                .padding(.vertical, 14)
            }
            //        .background(Color.white)
            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
            .shadow(
                color: Color.black.opacity(0.05),
                radius: AppConfig.UI.cardShadowRadius,
                x: 0,
                y: AppConfig.UI.cardShadowOffsetY
            )
            //            .overlay(
            //                RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
            //                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            //            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LetsReadCard()
}
