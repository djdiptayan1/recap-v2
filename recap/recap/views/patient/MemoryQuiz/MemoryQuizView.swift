//
//  MemoryCheckView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI
import UIKit

struct MemoryQuizView: View {
    @StateObject private var viewModel = MemoryQuizViewModel()
    @Environment(\.dismiss) var dismiss
    @AccessibilityFocusState private var focusedQuestionIndex: Int?
    
    private var currentQuestionNumber: Int {
        min(viewModel.currentIndex + 1, viewModel.questions.count)
    }
    
    private var progressPercentage: Int {
        guard !viewModel.questions.isEmpty else { return 0 }
        return Int((Double(currentQuestionNumber) / Double(viewModel.questions.count) * 100).rounded())
    }
    
    private let accessibilityFocusDelay: TimeInterval = 0.1
    
    private func moveFocusToQuestion(_ index: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + accessibilityFocusDelay) {
            focusedQuestionIndex = index
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading questions...")
                        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                            .accessibilityAddTraits(.isHeader)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            Task {
                                await viewModel.fetchQuestions()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityHint("Retry loading memory quiz questions.")
                    }
                } else if !viewModel.questions.isEmpty {
                    if viewModel.isSubmitting {
                        ProgressView("Submitting results...")
                            .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
                    } else if !viewModel.isCompleted {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Question \(viewModel.currentIndex + 1)")
                                    .font(AppConfig.Fonts.headline)
                                    .foregroundColor(AppConfig.Colors.textPrimary)
                                Spacer()
                                Text("\(viewModel.questions.count)")
                                    .font(AppConfig.Fonts.body)
                                    .foregroundColor(AppConfig.Colors.textSecondary)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                            .accessibilityValue("\(progressPercentage) percent complete")
                            .accessibilityAddTraits(.isHeader)
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(AppConfig.Colors.stroke)
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(AppConfig.Colors.accent)
                                        .frame(
                                            width: geo.size.width * viewModel.progress, height: 8
                                        )
                                        .animation(.smooth, value: viewModel.progress)
                                }
                            }
                            .frame(height: 8)
                            .accessibilityHidden(true)
                            .padding(AppConfig.UI.screenPadding)
                            .padding(.top, 30)
                            
                            Spacer()
                            
                            TabView(selection: $viewModel.currentIndex) {
                                ForEach(viewModel.questions.indices, id: \.self) { index in
                                    QuestionCard(question: viewModel.questions[index])
                                        .tag(index)
                                        .padding(.horizontal, AppConfig.UI.screenPadding)
                                        .accessibilityFocused($focusedQuestionIndex, equals: index)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                            .frame(height: 300)
                            .accessibilityHint("Swipe left or right to review the current set of questions.")
                            
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Button(action: {
                                    HapticManager.shared.trigger(.selection)
                                    viewModel.submitAnswer(isTrue: true)
                                }) {
                                    AnswerButtonLabel(text: "True", color: AppConfig.Colors.accent)
                                }
                                .accessibilityLabel("True")
                                .accessibilityHint("Select True as your answer.")
                                
                                Button(action: {
                                    HapticManager.shared.trigger(.selection)
                                    viewModel.submitAnswer(isTrue: false)
                                }) {
                                    AnswerButtonLabel(
                                        text: "False", color: AppConfig.Colors.textSecondary)
                                }
                                .accessibilityLabel("False")
                                .accessibilityHint("Select False as your answer.")
                            }
                            .padding(AppConfig.UI.screenPadding)
                            .padding(.bottom, 20)
                        }
                    } else {
                        QuizResultView(
                            result: viewModel.getResult(),
                            onRestart: {
                                HapticManager.shared.trigger(.selection)
                                viewModel.restart()
                            },
                            onExit: {
                                HapticManager.shared.trigger(.selection)
                                dismiss()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            HapticManager.shared.trigger(.success)
                            let result = viewModel.getResult()
                            UIAccessibility.post(
                                notification: .announcement,
                                argument: "Quiz complete. Your score is \(result.score) out of \(result.totalQuestions).")
                        }
                    }
                }
                //            .standardBackground()
            }
            .navigationTitle("Memory Check")
            .animation(.easeInOut, value: viewModel.isCompleted)
            .task {
                await viewModel.fetchQuestions()
            }
            .onChange(of: viewModel.currentIndex) { newIndex in
                moveFocusToQuestion(newIndex)
            }
            .onChange(of: viewModel.questions.count) { newCount in
                guard newCount > 0 else { return }
                moveFocusToQuestion(viewModel.currentIndex)
            }
        }
    }
    
    struct QuestionCard: View {
        let question: QuizQuestion
        
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppConfig.Colors.accent.opacity(0.6))
                    .accessibilityHidden(true)
                
                Text(question.question)
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(30)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(AppConfig.Colors.stroke, lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
        }
    }
    
    struct AnswerButtonLabel: View {
        let text: String
        let color: Color
        
        var body: some View {
            Text(text)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(color)
                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    MemoryQuizView()
}
