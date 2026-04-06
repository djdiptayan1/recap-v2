//
//  MemoryGameViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

// MARK: - Models

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let contentIcon: String
    var isFlipped = false
    var isMatched = false
    var rotation: Double = 0  // For animation
}

// MARK: - ViewModel

enum MatchManiaGameState {
    case instruction
    case playing
    case completed
}

class MemoryGameViewModel: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var moves: Int = 0
    @Published var timeElapsed: Int = 0
    @Published var matches: Int = 0
    @Published var gameState: MatchManiaGameState = .instruction

    // Internal State
    private var flippedCardIndex: Int?  // Tracks the first card flipped
    private var timer: Timer?
    private var isProcessing = false  // Prevents flipping more than 2 cards

    // Game Config
    private let icons = [
        "leaf.fill", "house.fill", "star.fill", "heart.fill",
        "moon.fill", "sun.max.fill", "car.fill", "bell.fill",
    ]

    init() {
        // Initial setup, but game starts in instruction mode
    }

    func startGame() {
        AnalyticsManager.shared.logEvent(name: AnalyticsManager.Events.gameStart, parameters: [
            AnalyticsManager.Parameters.gameType: "MatchMania"
        ])
        gameState = .playing
        startNewGame()
    }

    func startNewGame() {
        // 1. Reset Stats
        moves = 0
        timeElapsed = 0
        matches = 0
        flippedCardIndex = nil
        isProcessing = false
        timer?.invalidate()

        // 2. Create Pairs
        var newCards: [MemoryCard] = []
        for icon in icons {
            let card1 = MemoryCard(contentIcon: icon)
            let card2 = MemoryCard(contentIcon: icon)
            newCards.append(card1)
            newCards.append(card2)
        }

        // 3. Shuffle and Assign
        cards = newCards.shuffled()

        // 4. Start Timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.timeElapsed += 1
        }
    }

    func selectCard(_ card: MemoryCard) {
        // Block input if processing 2 cards
        if isProcessing { return }

        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }

        // Ignore if already matched or already flipped
        if cards[index].isMatched || cards[index].isFlipped { return }

        // 1. Flip the card
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            cards[index].isFlipped = true
            cards[index].rotation += 180
        }

        // Haptic Feedback
        HapticManager.shared.trigger(.light)

        // 2. Game Logic
        if let potentialMatchIndex = flippedCardIndex {
            // Second card flipped
            moves += 1
            isProcessing = true  // Lock input
            checkForMatch(index1: potentialMatchIndex, index2: index)
            flippedCardIndex = nil
        } else {
            // First card flipped
            flippedCardIndex = index
        }
    }

    private func checkForMatch(index1: Int, index2: Int) {
        if cards[index1].contentIcon == cards[index2].contentIcon {
            // MATCH!
            // Delay slightly to let the flip finish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut) {
                    self.cards[index1].isMatched = true
                    self.cards[index2].isMatched = true
                    self.matches += 1
                }

                // Success Haptic
                HapticManager.shared.trigger(.success)

                self.isProcessing = false  // Unlock input
                self.checkForWin()
            }
        } else {
            // NO MATCH
            // Flip back after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.cards[index1].isFlipped = false
                    self.cards[index2].isFlipped = false
                    self.cards[index1].rotation -= 180
                    self.cards[index2].rotation -= 180
                }
                self.isProcessing = false  // Unlock input
            }
        }
    }

    private func checkForWin() {
        if cards.allSatisfy({ $0.isMatched }) {
            timer?.invalidate()
            gameState = .completed
        }
    }
}
