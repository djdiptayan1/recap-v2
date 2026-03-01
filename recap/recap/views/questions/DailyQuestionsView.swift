//
//  DailyQuestionsView.swift
//  recap
//
//  Created by Diptayan Jash on 10/12/25.
//

import SwiftUI

struct DailyQuestionsView: View {
    @StateObject private var viewModel: DailyQuestionsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedAnswers: Set<String> = []

    init(patientId: String) {
        _viewModel = StateObject(wrappedValue: DailyQuestionsViewModel(patientId: patientId))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading Daily Check-in...")
                        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
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
                            viewModel.loadQuestions(role: appState.currentUser?.type ?? "patient")
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

                        // Answer Options
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(question.answerOptions, id: \.self) { option in
                                    Button(action: {
                                        HapticManager.shared.trigger(.selection)
                                        if selectedAnswers.contains(option) {
                                            selectedAnswers.remove(option)
                                        } else {
                                            selectedAnswers.insert(option)
                                        }
                                    }) {
                                        AnswerOptionButton(
                                            text: option,
                                            isSelected: selectedAnswers.contains(option))
                                    }
                                }
                            }
                            .padding(.horizontal, AppConfig.UI.screenPadding)
                            .padding(.bottom, 20)
                        }

                        // Submit Button
                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            let answeredBy =
                                appState.currentUser?.type == "patient" ? "patient" : "family"
                            viewModel.submitAnswer(Array(selectedAnswers), answeredBy: answeredBy)
                            selectedAnswers.removeAll()  // Clear for next question
                        }) {
                            Text("Submit Answer")
                                .font(AppConfig.Fonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    selectedAnswers.isEmpty ? Color.gray : AppConfig.Colors.accent
                                )
                                .cornerRadius(AppConfig.UI.buttonCornerRadius)
                        }
                        .disabled(selectedAnswers.isEmpty)
                        .padding(.horizontal, AppConfig.UI.screenPadding)
                        .padding(.bottom, 20)
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
            .animation(.easeInOut, value: viewModel.currentIndex)
            .onChange(of: viewModel.currentQuestion?.id) { _ in
                selectedAnswers.removeAll()
            }
            .onAppear {
                viewModel.loadQuestions(role: appState.currentUser?.type ?? "patient")
            }
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
                .font(AppConfig.Fonts.headline)  // Size 22
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
                        .font(AppConfig.Fonts.small)  // Size 14
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .italic()
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
//        .cornerRadius(AppConfig.UI.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                .stroke(AppConfig.Colors.stroke, lineWidth: 1)
        )
    }
}

struct AnswerOptionButton: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(text)
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(
                    isSelected ? AppConfig.Colors.accent : AppConfig.Colors.textPrimary)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? AppConfig.Colors.accent : AppConfig.Colors.stroke)
                .font(.system(size: 24))
        }
        .padding()
        .frame(height: 60)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
//        .cornerRadius(16)
        .shadow(
            color: isSelected ? AppConfig.Colors.accent.opacity(0.2) : Color.black.opacity(0.03),
            radius: 5, x: 0, y: 2
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? AppConfig.Colors.accent : AppConfig.Colors.stroke,
                    lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct CompletionView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(AppConfig.Colors.success)  // Green
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

            Button(action: {
                HapticManager.shared.trigger(.success)
                onDismiss()
            }) {
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
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
//        .cornerRadius(30)
        .shadow(radius: 20)
        .padding(.horizontal, 20)
    }
}

#Preview {
    DailyQuestionsView(patientId: "preview_patient_id")
}
