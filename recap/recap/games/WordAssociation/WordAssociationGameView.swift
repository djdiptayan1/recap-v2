//
//  WordAssociationGameView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

struct WordAssociationGameView: View {
    @StateObject private var viewModel = WordAssociationGameViewModel()
    @Environment(\.dismiss) var dismiss

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack {
            switch viewModel.currentPhase {
            case .instruction:
                WordAssociationInstructionView(onStart: viewModel.startGame)
                    .transition(.opacity)

            case .playing, .feedback:
                playingView
                    .transition(.opacity)

            case .completed:
                playingView
                    .transition(.opacity)
            }

            if viewModel.currentPhase == .completed {
                WordAssociationCompletionOverlay(
                    score: viewModel.score,
                    accuracy: viewModel.accuracy,
                    onRestart: viewModel.restartGame,
                    onDismiss: { dismiss() }
                )
            }
        }
        .animation(.easeInOut, value: viewModel.currentPhase)
        .navigationTitle("Word Link")
        .onDisappear {
            viewModel.handleViewDisappeared()
        }
    }

    // MARK: - Playing / Feedback View

    private var playingView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Round \(viewModel.roundProgress)")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                Spacer()
                Text("Score: \(viewModel.score)")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(AppConfig.Colors.accent)
            }
            .padding(.horizontal, AppConfig.UI.screenPadding)
            .padding(.top, 16)

            // Prompt word card
            VStack(spacing: 6) {
                Text("Find words related to:")
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(.white.opacity(0.85))
                Text(viewModel.promptWord)
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color(hex: "7B4FD9"), Color(hex: "B067E8")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppConfig.UI.cornerRadius)
            .shadow(color: Color(hex: "7B4FD9").opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.horizontal, AppConfig.UI.screenPadding)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Prompt word")
                .accessibilityValue(viewModel.promptWord)
            .padding(.top, 16)

            // Word grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.options) { option in
                    WordOptionButton(
                        option: option,
                        isInteractive: viewModel.currentPhase == .playing,
                        onTap: { viewModel.toggleWord(option) }
                    )
                }
            }
            .padding(.horizontal, AppConfig.UI.screenPadding)
            .padding(.top, 20)

            Spacer()

            // Action button
            if viewModel.currentPhase == .playing {
                Button(action: viewModel.submitAnswer) {
                    Text("Submit ✓")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7B4FD9"), Color(hex: "B067E8")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)
                        .shadow(color: Color(hex: "7B4FD9").opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, AppConfig.UI.screenPadding)
                .padding(.bottom, 24)
                .accessibilityInputLabels(["submit", "submit answer", "check"])
            } else if viewModel.currentPhase == .feedback {
                Button(action: viewModel.continueAfterFeedback) {
                    Text(viewModel.isLastRound ? "See Results 🏆" : "Next Round →")
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7B4FD9"), Color(hex: "B067E8")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)
                        .shadow(color: Color(hex: "7B4FD9").opacity(0.35), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, AppConfig.UI.screenPadding)
                .padding(.bottom, 24)
                .accessibilityInputLabels(["next round", "continue", "results"])
            }
        }
//        .standardBackground()
    }
}

// MARK: - Word Option Button

private struct WordOptionButton: View {
    let option: WordOption
    let isInteractive: Bool
    let onTap: () -> Void

    var backgroundColor: Color {
        switch option.feedbackState {
        case .correct:  return AppConfig.Colors.success.opacity(0.25)
        case .incorrect: return AppConfig.Colors.alert.opacity(0.25)
        case .missed:   return Color.orange.opacity(0.2)
        case .none:
            return option.isSelected ? AppConfig.Colors.accent.opacity(0.15) : Color.white
        }
    }

    var borderColor: Color {
        switch option.feedbackState {
        case .correct:  return AppConfig.Colors.success
        case .incorrect: return AppConfig.Colors.alert
        case .missed:   return Color.orange
        case .none:
            return option.isSelected ? AppConfig.Colors.accent : AppConfig.Colors.stroke
        }
    }

    var body: some View {
        Button(action: {
            if isInteractive { onTap() }
        }) {
            Text(option.word)
                .font(AppConfig.Fonts.bodyBold)
                .foregroundColor(AppConfig.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(backgroundColor)
                .cornerRadius(AppConfig.UI.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppConfig.UI.cornerRadius)
                        .stroke(borderColor, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .animation(.easeInOut(duration: 0.2), value: option.isSelected)
        .animation(.easeInOut(duration: 0.2), value: option.feedbackState)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(option.word)
        .accessibilityValue(accessibilityState)
        .accessibilityHint(isInteractive ? "Double tap to select or deselect" : "Review only")
        .accessibilityInputLabels([option.word.lowercased(), "word", "option"])
    }

    private var accessibilityState: String {
        switch option.feedbackState {
        case .correct: return "Correct"
        case .incorrect: return "Incorrect"
        case .missed: return "Missed"
        case .none: return option.isSelected ? "Selected" : "Not selected"
        }
    }
}

#Preview {
    NavigationStack {
        WordAssociationGameView()
    }
}
