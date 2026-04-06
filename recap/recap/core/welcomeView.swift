//
//  welcomeView.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI
struct welcomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    Image("recapLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.bottom, 10)

                    Text("Recap")
                        .font(AppConfig.Fonts.titleLarge)
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Text("Your memories, preserved together.")
                        .font(AppConfig.Fonts.body)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)

                VStack(spacing: 24) {
                    HStack {
                        Text("Choose your role")
                            .font(AppConfig.Fonts.small)
                            .textCase(.uppercase)
                            .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.8))
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    RoleCard(
                        icon: "heart.fill",
                        title: "Patient",
                        description: "Your memories are precious—let's keep them close, together.",
                        destination: PatientLoginView()
                    )

                    RoleCard(
                        icon: "person.3.fill",
                        title: "Family",
                        description: "Monitor and support your loved ones. Keep track together.",
                        destination: FamilyLoginView()
                    )
                }
                .padding(.horizontal, AppConfig.UI.screenPadding)

                Spacer()
            }
            .standardBackground()
            .onAppear {
                AnalyticsManager.shared.logScreen(name: "Welcome")
            }
        }
    }
}

#Preview {
    welcomeView()
}
