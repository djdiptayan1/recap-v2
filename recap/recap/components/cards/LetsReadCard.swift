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
                        .accessibilityHidden(true)
                }
                .padding(AppConfig.UI.padding)

                Divider()
                    .background(AppConfig.Colors.stroke)
                    .padding(.horizontal, AppConfig.UI.padding)

                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Discover new stories")
                            .font(AppConfig.Fonts.bodyBold)
                            .foregroundColor(AppConfig.Colors.textPrimary)

                        Text("Reading keeps the mind active and curious.")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .lineLimit(2)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppConfig.Colors.accent.opacity(0.3))
                        .accessibilityHidden(true)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Let's Read")
        .accessibilityHint("Discover new stories. Tap to browse articles.")
        .accessibilityAddTraits(.isButton)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LetsReadCard()
}
