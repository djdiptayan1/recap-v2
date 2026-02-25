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

    private let bubbleColors: [Color] = [
        Color(red: 1.0,  green: 0.30, blue: 0.30),  // Red
        Color(red: 1.0,  green: 0.60, blue: 0.10),  // Orange
        Color(red: 1.0,  green: 0.82, blue: 0.00),  // Yellow
        Color(red: 0.18, green: 0.80, blue: 0.44),  // Green
        Color(red: 0.20, green: 0.55, blue: 0.95),  // Blue
        Color(red: 0.60, green: 0.18, blue: 0.92),  // Purple
        Color(red: 1.0,  green: 0.25, blue: 0.60),  // Pink
        Color(red: 0.05, green: 0.75, blue: 0.75),  // Teal
        Color(red: 0.65, green: 0.88, blue: 0.10),  // Lime
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
        nextTarget = 1
        timeRemaining = totalTime
        let shuffledPositions = positions.shuffled()
        let shuffledColors = bubbleColors.shuffled()
        bubbles = (1...bubbleCount).map { i in
            let pos = shuffledPositions[i - 1]
            return Bubble(
                number: i,
                color: shuffledColors[(i - 1) % shuffledColors.count],
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
            nextTarget += 1
            if nextTarget > bubbleCount {
                timer?.invalidate()
                score += timeRemaining * level  // Time bonus
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
