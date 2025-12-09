//
//  DailyQuestionsView.swift
//  recap
//
//  Created by Diptayan Jash on 10/12/25.
//

import SwiftUI

struct DailyQuestionsView: View {
    @StateObject private var viewModel = DailyQuestionsViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading Daily Check-in...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Something went wrong")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            viewModel.fetchQuestions()
                        }
                    }
                } else if viewModel.isCompleted {
                    // 2. Completion State
                    CompletionView(onDismiss: { dismiss() })
                        .transition(.opacity)
                } else if let question = viewModel.currentQuestion {
                    // 3. Question Flow
                    VStack(spacing: 24) {
                        
                        // Progress Bar
                        ProgressBar(value: viewModel.progress)
                            .padding(.horizontal, AppConfig.UI.screenPadding)
                            .padding(.top, 10)
                        
                        // Question Card
                        QuestionDisplayCard(question: question)
                            .padding(.horizontal, AppConfig.UI.screenPadding)
                        
                        // Answer Options (Scrollable if many options)
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(question.answerOptions, id: \.self) { option in
                                    Button(action: { viewModel.submitAnswer(option) }) {
                                        AnswerOptionButton(text: option)
                                    }
                                }
                            }
                            .padding(.horizontal, AppConfig.UI.screenPadding)
                            .padding(.bottom, 20)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Questions Available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .standardBackground()
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Exit") { dismiss() }
//                        .foregroundColor(AppConfig.Colors.textSecondary)
//                }
//            }
            .animation(.easeInOut, value: viewModel.currentIndex)
        }
    }
}

// MARK: - Subcomponents

struct ProgressBar: View {
    var value: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(AppConfig.Fonts.small)
                .foregroundColor(AppConfig.Colors.textSecondary)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppConfig.Colors.stroke)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(AppConfig.Colors.accent)
                        .frame(width: geo.size.width * value, height: 6)
                        .animation(.spring(), value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

struct QuestionDisplayCard: View {
    let question: QuestionModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Tag
//            Text(question.subcategory.capitalized)
//                .font(.caption)
//                .fontWeight(.bold)
//                .foregroundColor(AppConfig.Colors.accent)
//                .padding(.horizontal, 10)
//                .padding(.vertical, 4)
//                .background(AppConfig.Colors.accent.opacity(0.1))
//                .cornerRadius(8)
            
            // The Question
            Text(question.text)
                .font(AppConfig.Fonts.headline) // Size 22
                .foregroundColor(AppConfig.Colors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // Hint (if available)
            if let hint = question.hint, !hint.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(hint)
                        .font(AppConfig.Fonts.small) // Size 14
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .italic()
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
        )
    }
}

struct AnswerOptionButton: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(AppConfig.Fonts.bodyBold) // Size 18, readable
                .foregroundColor(AppConfig.Colors.textPrimary)
            
            Spacer()
            
            Image(systemName: "circle")
                .foregroundColor(AppConfig.Colors.stroke)
                .font(.system(size: 20))
        }
        .padding()
        .frame(height: 60)
        .background(Color.white)
        .cornerRadius(16)
        // Soft shadow to lift button off background
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
        )
    }
}

struct CompletionView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.success) // Green
                .shadow(color: AppConfig.Colors.success.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("All Done!")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                
                Text("Great job completing your daily check-in.")
                    .font(AppConfig.Fonts.body)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onDismiss) {
                Text("Finish")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppConfig.Colors.textPrimary)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
            }
            .padding(.top, 20)
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(30)
        .shadow(radius: 20)
        .padding(.horizontal, 20)
    }
}

#Preview {
    DailyQuestionsView()
}
