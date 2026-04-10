//
//  DailyObjectsGameView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct DailyObjectsGameView: View {
    @StateObject private var viewModel = DailyObjectsGameViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    switch viewModel.currentPhase {
                    case .instruction:
                        InstructionView(onStart: viewModel.startGame)
                            .transition(.opacity)
                        
                    case .memorizing:
                        MemorizePhaseView(
                            objects: viewModel.objectsToMemorize,
                            timeProgress: viewModel.timeRemaining,
                            timeString: viewModel.timerString,
                            onReady: viewModel.startRecallPhase
                        )
                        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                        
                    case .recalling:
                        RecallPhaseView(
                            allObjects: viewModel.recallGridObjects,
                            selectedIDs: viewModel.selectedIDs,
                            onToggle: viewModel.toggleSelection,
                            onSubmit: viewModel.submitAnswers
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                        
                    case .roundSummary:
                        RoundSummaryView(
                            score: viewModel.score,
                            onNext: viewModel.nextRound
                        )
                        .transition(.scale)
                    case .completed:
                        DailyObjectsCompletionOverlay(
                            score: viewModel.score,
                            accuracy: viewModel.accuracyPercentage,
                            onRestart: viewModel.startGame,
                            onDismiss: { dismiss() }
                        )
                        .transition(.scale)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentPhase)
                
                Spacer()
            }
//            .standardBackground()
            .navigationTitle("Daily Objects")
            .onDisappear {
                viewModel.handleViewDisappeared()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Round \(min(viewModel.currentRound, viewModel.maxRounds))/\(viewModel.maxRounds)")
                            .font(AppConfig.Fonts.small)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                        Text("Score: \(viewModel.score)")
                            .font(AppConfig.Fonts.headline)
                            .foregroundColor(AppConfig.Colors.accent)
                    }
                    .padding(20)
                }
            }
        }
    }
}

private struct DailyObjectsCompletionOverlay: View {
    let score: Int
    let accuracy: Int
    let onRestart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundColor(.yellow)

                Text("Session Complete")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)

                VStack(spacing: 8) {
                    Text("Final Score: \(score)")
                    Text("Accuracy: \(accuracy)%")
                }
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)

                HStack(spacing: 14) {
                    Button("Exit", action: onDismiss)
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .frame(width: 100, height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)

                    Button("Play Again", action: onRestart)
                        .font(AppConfig.Fonts.headline)
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(AppConfig.Colors.accent)
                        .cornerRadius(AppConfig.UI.buttonCornerRadius)
                }
            }
            .padding(36)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 36)
        }
    }
}

#Preview {
    DailyObjectsGameView()
}
