//
//  PatternMemoryGameView.swift
//  recap
//
//  Created by user on 25/02/26.
//

import SwiftUI

struct PatternMemoryGameView: View {
    @StateObject private var viewModel = PatternMemoryGameViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            switch viewModel.currentPhase {
            case .instruction:
                PatternMemoryInstructionView(onStart: viewModel.startGame)
                    .transition(.opacity)

            case .watching, .repeating, .feedback:
                gameView
                    .transition(.opacity)

            case .gameOver:
                gameView
                    .transition(.opacity)
            }

            if viewModel.currentPhase == .gameOver {
                PatternMemoryGameOverOverlay(
                    level: viewModel.level,
                    score: viewModel.score,
                    onRestart: viewModel.restartGame,
                    onDismiss: { dismiss() }
                )
            }
        }
        .animation(.easeInOut, value: viewModel.currentPhase)
        .navigationTitle("Pattern Memory")
        .onDisappear {
            viewModel.handleViewDisappeared()
        }
    }

    // MARK: - Main Game View

    private var gameView: some View {
        VStack(spacing: 0) {
            // Stats row
            HStack {
                StatLabel(icon: "arrow.up.circle.fill", label: "Level", value: "\(viewModel.level)")
                Spacer()
                StatLabel(icon: "star.fill", label: "Score", value: "\(viewModel.score)")
                Spacer()
                StatLabel(icon: "heart.fill", label: "Lives", value: "\(viewModel.lives)")
            }
            .padding(.horizontal, AppConfig.UI.screenPadding)
            .padding(.top, 16)

            // Phase label
            Text(phaseLabel)
                .font(AppConfig.Fonts.headline)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Spacer()

            // 2x2 Tile grid
            let gridSize = UIScreen.main.bounds.width - AppConfig.UI.screenPadding * 2
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    PatternMemoryTileView(
                        tile: viewModel.tiles[0],
                        isLit: viewModel.litTileID == 0 || viewModel.highlightedTileID == 0,
                        isInteractive: viewModel.currentPhase == .repeating,
                        onTap: { viewModel.playerTapped(tileID: 0) }
                    )
                    PatternMemoryTileView(
                        tile: viewModel.tiles[1],
                        isLit: viewModel.litTileID == 1 || viewModel.highlightedTileID == 1,
                        isInteractive: viewModel.currentPhase == .repeating,
                        onTap: { viewModel.playerTapped(tileID: 1) }
                    )
                }
                HStack(spacing: 16) {
                    PatternMemoryTileView(
                        tile: viewModel.tiles[2],
                        isLit: viewModel.litTileID == 2 || viewModel.highlightedTileID == 2,
                        isInteractive: viewModel.currentPhase == .repeating,
                        onTap: { viewModel.playerTapped(tileID: 2) }
                    )
                    PatternMemoryTileView(
                        tile: viewModel.tiles[3],
                        isLit: viewModel.litTileID == 3 || viewModel.highlightedTileID == 3,
                        isInteractive: viewModel.currentPhase == .repeating,
                        onTap: { viewModel.playerTapped(tileID: 3) }
                    )
                }
            }
            .frame(width: gridSize, height: gridSize)

            Spacer()

            // Feedback section
            if viewModel.currentPhase == .feedback {
                feedbackView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 24)
            }
        }
//        .standardBackground()
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentPhase)
    }

    private var phaseLabel: String {
        switch viewModel.currentPhase {
        case .watching:  return "Watch carefully..."
        case .repeating: return "Your turn! Tap the sequence."
        case .feedback:  return viewModel.lastAnswerCorrect ? "🎉 Correct!" : "❌ Wrong sequence"
        default:         return ""
        }
    }

    private var feedbackView: some View {
        VStack(spacing: 12) {
            Text(viewModel.lastAnswerCorrect
                 ? "Great job! Next round is longer."
                 : (viewModel.lives > 0 ? "Try again — \(viewModel.lives) \(viewModel.lives == 1 ? "life" : "lives") left." : "No lives left!"))
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppConfig.UI.screenPadding)

            Button(action: viewModel.continueAfterFeedback) {
                Text(viewModel.lives <= 0 ? "See Results" : "Continue")
                    .font(AppConfig.Fonts.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(AppConfig.Colors.accent)
                    .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    .shadow(color: AppConfig.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, AppConfig.UI.screenPadding)
        }
    }
}

// MARK: - Stat Label

private struct StatLabel: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(AppConfig.Colors.accent)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppConfig.Fonts.small)
                    .foregroundColor(AppConfig.Colors.textSecondary)
                Text(value)
                    .font(AppConfig.Fonts.bodyBold)
                    .foregroundColor(AppConfig.Colors.textPrimary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Game Over Overlay

private struct PatternMemoryGameOverOverlay: View {
    let level: Int
    let score: Int
    let onRestart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .shadow(radius: 5)

                Text("Game Over!")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                VStack(spacing: 8) {
                    Text("Highest Level: \(level)")
                    Text("Total Score: \(score)")
                }
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)

                HStack(spacing: 16) {
                    Button(action: onDismiss) {
                        Text("Exit")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .frame(width: 100, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    }

                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(.white)
                            .frame(width: 140, height: 50)
                            .background(AppConfig.Colors.accent)
                            .cornerRadius(AppConfig.UI.buttonCornerRadius)
                    }
                }
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    NavigationStack {
        PatternMemoryGameView()
    }
}
