//
//  RoleCardView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct RoleCard<Destination: View>: View {
    let icon: String
    let title: String
    let description: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppConfig.Colors.accent.opacity(0.15))

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(AppConfig.Colors.accent)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text(description)
                        .font(AppConfig.Fonts.small)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppConfig.Colors.stroke)
                    .accessibilityHidden(true)
            }
            .padding(AppConfig.UI.padding)
            //            .background(AppConfig.Colors.card)
            .glassEffect(.clear, in: .rect)
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: AppConfig.UI.cardShadowRadius * 2,
                x: 0,
                y: AppConfig.UI.cardShadowOffsetY * 2
            )
            //            .overlay(
            //                 RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
            //                  .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            //             )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityHint("Tap to continue as \(title).")
        .accessibilityAddTraits(.isButton)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
struct RoleCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {

            VStack(spacing: 20) {
                RoleCard(
                    icon: "heart.fill",
                    title: "Patient",
                    description: "Your memories are precious—let's keep them close, together.",
                    destination: PatientLoginView()
                )

                //                RoleCard(
                //                    icon: "person.3.fill",
                //                    title: "Family",
                //                    description: "Monitor and support your loved ones. You can help keep track.",
                ////                    destination: FamilyLoginView()
                //                )
            }
            .padding()
        }
        .standardBackground()
    }
}
