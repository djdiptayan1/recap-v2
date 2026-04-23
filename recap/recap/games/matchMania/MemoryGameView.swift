//
//  MemoryGameView.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import SwiftUI

struct MemoryGameView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    @Environment(\.dismiss) var dismiss
    
    // Grid Layout: 4 columns for 16 cards
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            AppConfig.Colors.background
                .ignoresSafeArea()
            
            if viewModel.gameState == .instruction {
                MatchManiaInstructionView(onStart: viewModel.startGame)
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    
                    // --- Header Stats ---
                    HStack {
                        StatBadge(icon: "clock", value: formatTime(viewModel.timeElapsed))
                        Spacer()
                        StatBadge(icon: "checkmark.circle.fill", value: "\(viewModel.matches)/8 Pairs")
                        Spacer()
                        StatBadge(icon: "arrow.left.arrow.right", value: "\(viewModel.moves) Moves")
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // --- Game Grid ---
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.cards) { card in
                            Button(action: {
                                viewModel.selectCard(card)
                            }) {
                                CardView(card: card)
                            }
                            .buttonStyle(.plain)
                            .accessibilityInputLabels([card.contentIcon.replacingOccurrences(of: ".fill", with: ""), "card", "memory card"])
                            .accessibilityLabel(cardLabel(for: card))
                            .accessibilityValue(cardValue(for: card))
                            .accessibilityHint("Flip this card to look for a match")
                        }
                    }
                    .padding(.horizontal, AppConfig.UI.screenPadding)
                }
                .transition(.opacity)
            }
            
            // --- Completion Overlay ---
            if viewModel.gameState == .completed {
                GameCompletionOverlay(
                    moves: viewModel.moves,
                    time: formatTime(viewModel.timeElapsed),
                    onRestart: viewModel.startNewGame,
                    onDismiss: { dismiss() }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle("Match Mania")
        .animation(.easeInOut, value: viewModel.gameState)
        .onDisappear {
            viewModel.handleViewDisappeared()
        }
    }

    private func cardLabel(for card: MemoryCard) -> String {
        if card.isMatched {
            return "Matched card"
        }
        if card.isFlipped {
            return "Face up card"
        }
        return "Face down card"
    }

    private func cardValue(for card: MemoryCard) -> String {
        if card.isMatched {
            return "Matched"
        }
        if card.isFlipped {
            return "Revealed"
        }
        return "Hidden"
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let min = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

// MARK: - UI Components

struct StatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppConfig.Colors.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(AppConfig.Colors.textPrimary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(value)
    }
}

struct CardView: View {
    let card: MemoryCard
    
    var body: some View {
        ZStack {
            // BACK of Card (Visible when NOT flipped)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [AppConfig.Colors.accent, AppConfig.Colors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 24))
                )
                .opacity(card.isFlipped ? 0 : 1)
            
            // FRONT of Card (Visible when flipped)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Image(systemName: card.contentIcon)
                    .font(.system(size: 32))
                    .foregroundColor(card.isMatched ? .green : AppConfig.Colors.accent)
            }
            .opacity(card.isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(180), // Correct the mirroring text caused by the flip
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
        }
        .frame(height: 80) // Fixed height for consistency
        .rotation3DEffect(
            .degrees(card.rotation),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        // If matched, fade it out slightly to indicate "Done"
        .opacity(card.isMatched ? 0.6 : 1)
        .animation(.default, value: card.isMatched)
        .accessibilityHidden(true)
    }
}

struct GameCompletionOverlay: View {
    let moves: Int
    let time: String
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
                    .accessibilityHidden(true)
                
                Text("Excellent Memory!")
                    .font(AppConfig.Fonts.titleMedium)
                    .foregroundColor(AppConfig.Colors.textPrimary)
                
                VStack(spacing: 8) {
                    Text("Time: \(time)")
                    Text("Moves: \(moves)")
                }
                .font(AppConfig.Fonts.body)
                .foregroundColor(AppConfig.Colors.textSecondary)
                
                HStack(spacing: 16) {
                    Button(action: onDismiss) {
                        Text("Exit")
                            .font(.headline)
                            .foregroundColor(AppConfig.Colors.textSecondary)
                            .frame(width: 100, height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onRestart) {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 140, height: 50)
                            .background(AppConfig.Colors.accent)
                            .cornerRadius(12)
                    }
                }
            }
            .accessibilityElement(children: .combine)
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
        MemoryGameView()
    }
}
