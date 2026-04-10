//
//  PatternMemoryGameViewModel.swift
//  recap
//
//  Created by user on 25/02/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct PatternTile: Identifiable {
    let id: Int
    let color: Color
    let name: String
    var isLit: Bool = false
}

enum PatternMemoryPhase {
    case instruction
    case watching
    case repeating
    case feedback
    case gameOver
}

// MARK: - ViewModel

class PatternMemoryGameViewModel: ObservableObject {

    let tiles: [PatternTile] = [
        PatternTile(id: 0, color: .blue,   name: "Blue"),
        PatternTile(id: 1, color: Color(red: 0.18, green: 0.8, blue: 0.44), name: "Green"),
        PatternTile(id: 2, color: Color(red: 1.0,  green: 0.58, blue: 0.0), name: "Orange"),
        PatternTile(id: 3, color: Color(red: 0.6,  green: 0.2,  blue: 0.8), name: "Purple"),
    ]

    @Published var currentPhase: PatternMemoryPhase = .instruction
    @Published var litTileID: Int? = nil
    @Published var sequence: [Int] = []
    @Published var playerInput: [Int] = []
    @Published var level: Int = 1
    @Published var lives: Int = 2
    @Published var score: Int = 0
    @Published var lastAnswerCorrect: Bool = true
    @Published var highlightedTileID: Int? = nil

    private var showSequenceTask: Task<Void, Never>? = nil
    private var sessionStartedAt = Date()
    private var hasSubmittedSession = false
    private var successfulRounds = 0
    private var failedRounds = 0
    private var mistakeCount = 0
    private var maxSequenceLength = 1

    // MARK: - Game Control

    func startGame() {
        level = 1
        lives = 2
        score = 0
        sequence = []
        playerInput = []
        sessionStartedAt = Date()
        hasSubmittedSession = false
        successfulRounds = 0
        failedRounds = 0
        mistakeCount = 0
        maxSequenceLength = 1
        
        AnalyticsManager.shared.logEvent(name: AnalyticsManager.Events.gameStart, parameters: [
            AnalyticsManager.Parameters.gameType: "PatternMemory"
        ])
        
        startNewRound()
    }

    func startNewRound() {
        playerInput = []
        appendToSequence()
        withAnimation { currentPhase = .watching }
        showSequence()
    }

    private func appendToSequence() {
        let nextTile = Int.random(in: 0..<tiles.count)
        sequence.append(nextTile)
        maxSequenceLength = max(maxSequenceLength, sequence.count)
    }

    private func showSequence() {
        showSequenceTask?.cancel()
        showSequenceTask = Task { @MainActor in
            // Small pause before showing
            try? await Task.sleep(nanoseconds: 500_000_000)
            for tileID in sequence {
                guard !Task.isCancelled else { return }
                litTileID = tileID
                try? await Task.sleep(nanoseconds: 700_000_000)
                litTileID = nil
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            guard !Task.isCancelled else { return }
            withAnimation { currentPhase = .repeating }
        }
    }

    func playerTapped(tileID: Int) {
        guard currentPhase == .repeating else { return }
        HapticManager.shared.trigger(.selection)

        // Brief highlight on tap
        highlightedTileID = tileID
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            highlightedTileID = nil
        }

        playerInput.append(tileID)
        let step = playerInput.count - 1

        if playerInput[step] != sequence[step] {
            // Wrong
            HapticManager.shared.trigger(.error)
            lives -= 1
            lastAnswerCorrect = false
            failedRounds += 1
            mistakeCount += 1
            withAnimation { currentPhase = .feedback }
            return
        }

        if playerInput.count == sequence.count {
            // Correct full sequence
            HapticManager.shared.trigger(.success)
            score += level * 10
            level += 1
            lastAnswerCorrect = true
            successfulRounds += 1
            withAnimation { currentPhase = .feedback }
        }
    }

    func continueAfterFeedback() {
        if lives <= 0 {
            AnalyticsManager.shared.logEvent(name: AnalyticsManager.Events.gameComplete, parameters: [
                AnalyticsManager.Parameters.gameType: "PatternMemory",
                AnalyticsManager.Parameters.score: score,
                "final_level": level
            ])
            withAnimation { currentPhase = .gameOver }
            Task { @MainActor in
                await submitSessionIfNeeded(outcome: .livesExhausted, completed: true)
            }
        } else if lastAnswerCorrect {
            startNewRound()
        } else {
            // Retry same level
            sequence.removeLast()
            level = max(1, level - 1)
            startNewRound()
        }
    }

    func restartGame() {
        showSequenceTask?.cancel()
        litTileID = nil
        startGame()
    }

    func handleViewDisappeared() {
        showSequenceTask?.cancel()
        Task { @MainActor in
            await submitSessionIfNeeded(outcome: .exited, completed: false)
        }
    }

    @MainActor
    private func submitSessionIfNeeded(outcome: GameSessionOutcome, completed: Bool) async {
        guard !hasSubmittedSession else { return }
        guard currentPhase != .instruction else { return }
        guard let documentId = GameSessionService.shared.currentPatientDocumentID() else { return }
        hasSubmittedSession = true

        let totalRounds = successfulRounds + failedRounds
        let accuracy = totalRounds == 0 ? 0 : Int((Double(successfulRounds) / Double(totalRounds)) * 100)

        let request = GameSessionSubmissionBuilder(
            gameType: .patternMemory,
            score: score,
            durationSeconds: Int(Date().timeIntervalSince(sessionStartedAt)),
            startedAt: sessionStartedAt,
            completedAt: Date(),
            outcome: outcome,
            completed: completed,
            levelReached: max(1, level),
            accuracy: Double(accuracy),
            mistakes: mistakeCount,
            difficulty: "progressive",
            metadata: [
                "exitPhase": "\(currentPhase)",
                "completed": "\(completed)",
                "successfulRounds": "\(successfulRounds)",
                "failedRounds": "\(failedRounds)",
                "maxSequenceLength": "\(maxSequenceLength)",
            ]
        ).makeRequest(documentId: documentId)

        do {
            try await GameSessionService.shared.submitSession(request)
        } catch {
            print("Failed to submit Pattern Memory session: \(error)")
        }
    }
}
