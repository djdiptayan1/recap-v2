//
//  familyQuestionMain.swift
//  recap
//
//  Created by Diptayan Jash on 01/01/26.
//

import SwiftUI

struct familyQuestionMain: View {
    @State private var showAnswerSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                    
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                                .font(.system(size: 48))
                                .foregroundColor(AppConfig.Colors.accent)
                                .padding()
                                .background(
                                    Circle()
                                        .fill(AppConfig.Colors.accent.opacity(0.1))
                                )
                            
                            Text("Family Questions")
                                .font(AppConfig.Fonts.titleMedium)
                                .foregroundColor(AppConfig.Colors.textPrimary)
                            
                            Text("Engage with your loved one by managing or answering daily questions.")
                                .font(AppConfig.Fonts.body)
                                .foregroundColor(AppConfig.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        VStack(spacing: 20) {
                            
                            // 1. Answer Today's Questions
                            NavigationLink(destination: Text("Answer View Placeholder")) {
                                QuestionOptionCard(
                                    title: "Answer Questions",
                                    subtitle: "Help fill in the gaps for today.",
                                    icon: "square.and.pencil",
                                    color: AppConfig.Colors.accent
                                )
                            }

                            NavigationLink(destination: Text("Add Questions View Placeholder")) {
                                QuestionOptionCard(
                                    title: "Add New Question",
                                    subtitle: "Create personalized memory prompts.",
                                    icon: "plus.circle.fill",
                                    color: AppConfig.Colors.success
                                )
                            }
                            
                            NavigationLink(destination: Text("Edit Questions View Placeholder")) {
                                QuestionOptionCard(
                                    title: "Edit Question Bank",
                                    subtitle: "Manage existing questions and answers.",
                                    icon: "slider.horizontal.3",
                                    color: Color.orange
                                )
                            }
                        }
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                    }
                    .padding(.bottom, 40)
                }
            }
//            .standardBackground()
            .navigationTitle("Questions")
        }
    }
}


struct QuestionOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {

            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppConfig.Colors.stroke)
        }
        .padding(16)
        .glassEffect(.clear, in: .rect)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
//        .overlay(
//            RoundedRectangle(cornerRadius: 20)
//                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
//        )
        .contentShape(Rectangle())
    }
}

#Preview {
    familyQuestionMain()
}
