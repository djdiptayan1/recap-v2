//
//  QuestionsCard.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import SwiftUI

struct QuestionsCard: View {
    @EnvironmentObject var appState: AppState
    var hasFamilyMembers: Bool = true
    @State private var showAddMemberAlert = false

    var body: some View {
        Group {
            if let user = appState.currentUser, user.type == "patient" && !hasFamilyMembers {
                Button(action: {
                    showAddMemberAlert = true
                }) {
                    cardContent
                }
                .alert("Add Family Member", isPresented: $showAddMemberAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please add a caretaker/family member to start answering questions.")
                }
            } else {
                NavigationLink(destination: destinationView) {
                    cardContent
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Questions")
        .accessibilityHint("Opens the daily questions flow")
        .accessibilityInputLabels(["daily questions", "questions", "check in"])
    }

    private var cardContent: some View {
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image("oldMan")
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
        //        .cornerRadius(AppConfig.UI.cornerRadius)
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

    @ViewBuilder
    private var destinationView: some View {
        if appState.isLoggedIn {
            if appState.currentUser?.type == "patient", let patientId = appState.currentUser?.id {
                DailyQuestionsView(patientId: patientId)
                    .environmentObject(appState)
            } else {
                familyQuestionMain()
                    .environmentObject(appState)
            }
        }
    }
}

#Preview {
    QuestionsCard()
        .environmentObject(AppState())
}
