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
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentPhase)
                
                Spacer()
            }
            .standardBackground()
            .navigationTitle("Daily Objects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    VStack(alignment: .trailing, spacing: 2) {
//                        Text("Round \(viewModel.currentRound)")
//                            .font(AppConfig.Fonts.small)
//                            .foregroundColor(AppConfig.Colors.textSecondary)
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

#Preview {
    DailyObjectsGameView()
}
