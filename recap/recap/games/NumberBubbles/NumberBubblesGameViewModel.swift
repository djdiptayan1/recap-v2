//
//  NumberBubblesGameViewModel.swift
//  recap
//
//  Created by user on 25/02/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct Bubble: Identifiable {
    let id = UUID()
    let number: Int
    let color: Color
    let posX: CGFloat  // 0.0–1.0 normalized relative to canvas
    let posY: CGFloat  // 0.0–1.0 normalized relative to canvas
    var isPopped: Bool = false
}

enum BubblesPhase {
    case instruction
    case playing
    case levelComplete
    case gameOver
}

// MARK: - ViewModel

class NumberBubblesGameViewModel: ObservableObject {

    @Published var phase: BubblesPhase = .instruction
    @Published var bubbles: [Bubble] = []
    @Published var nextTarget: Int = 1
    @Published var level: Int = 1
    @Published var score: Int = 0
    @Published var timeRemaining: Int = 20
    @Published var wrongTapID: UUID? = nil

    private var timer: Timer?

    // Colors drawn from the app's palette: accent teal, coral, lime, indigo, orange, sky-blue, mint, rose, sage
    private let bubbleColors: [Color] = [
        Color(hex: "8DD3BB"),  // Accent teal
        Color(hex: "E86C6C"),  // Alert coral
        Color(hex: "A8E063"),  // Success lime
        Color(hex: "7B8FD9"),  // Indigo (muted)
        Color(hex: "F4956A"),  // Warm orange
        Color(hex: "2CBFCE"),  // Sky teal
        Color(hex: "3DBA7A"),  // Emerald green
        Color(hex: "C97BE8"),  // Soft purple
        Color(hex: "F4C06A"),  // Warm amber
    ]

    // 9 pre-defined positions spread across the canvas (normalized 0–1)
    private let positions: [(CGFloat, CGFloat)] = [
        (0.20, 0.13), (0.55, 0.09), (0.82, 0.17),
        (0.13, 0.42), (0.50, 0.40), (0.85, 0.44),
        (0.22, 0.71), (0.54, 0.74), (0.82, 0.67),
    ]

    var bubbleCount: Int { min(4 + level, 9) }
    var totalTime: Int { 14 + level * 4 }

    // MARK: - Game Control

    func startGame() {
        level = 1
        score = 0
        startLevel()
    }

    func startLevel() {
        timeRemaining = totalTime
        // Pick bubbleCount random distinct numbers from a range scaled to the level,
        // then sort them so the player taps smallest → largest.
        let rangeMax = bubbleCount * (3 + level)
        var pool = Array(1...rangeMax)
        pool.shuffle()
        let chosen = Array(pool.prefix(bubbleCount)).sorted()
        nextTarget = chosen[0]

        let shuffledPositions = positions.shuffled()
        let shuffledColors = bubbleColors.shuffled()
        bubbles = chosen.enumerated().map { i, number in
            let pos = shuffledPositions[i]
            return Bubble(
                number: number,
                color: shuffledColors[i % shuffledColors.count],
                posX: pos.0,
                posY: pos.1
            )
        }
        withAnimation { phase = .playing }
        startTimer()
    }

    func tapBubble(_ bubble: Bubble) {
        guard phase == .playing, !bubble.isPopped else { return }

        if bubble.number == nextTarget {
            HapticManager.shared.trigger(.success)
            if let idx = bubbles.firstIndex(where: { $0.id == bubble.id }) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                    bubbles[idx].isPopped = true
                }
            }
            score += 10 * level
            // Find the next smallest un-popped bubble number
            let remaining = bubbles.filter { !$0.isPopped && $0.number != bubble.number }
                                   .map { $0.number }.sorted()
            if let next = remaining.first {
                nextTarget = next
            } else {
                // All popped
                timer?.invalidate()
                score += timeRemaining * level
                withAnimation { phase = .levelComplete }
            }
        } else {
            HapticManager.shared.trigger(.error)
            let bubbleID = bubble.id
            wrongTapID = bubbleID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if self.wrongTapID == bubbleID { self.wrongTapID = nil }
            }
        }
    }

    func nextLevel() {
        level += 1
        startLevel()
    }

    func restartGame() {
        timer?.invalidate()
        level = 1
        score = 0
        startLevel()
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                HapticManager.shared.trigger(.warning)
                withAnimation { self.phase = .gameOver }
            }
        }
    }
}
