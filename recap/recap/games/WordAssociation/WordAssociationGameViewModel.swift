//
//  WordAssociationGameViewModel.swift
//  recap
//
//  Created by user on 25/02/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct WordSet {
    let prompt: String
    let correct: [String]
    let distractors: [String]
}

struct WordOption: Identifiable {
    let id = UUID()
    let word: String
    var isSelected: Bool = false
    var feedbackState: WordFeedbackState = .none
}

enum WordFeedbackState {
    case none
    case correct
    case incorrect
    case missed
}

enum WordAssociationPhase {
    case instruction
    case playing
    case feedback
    case completed
}

// MARK: - ViewModel

class WordAssociationGameViewModel: ObservableObject {

    private let allWordSets: [WordSet] = [
        WordSet(prompt: "Kitchen",   correct: ["Oven", "Spatula", "Plate"],   distractors: ["Pillow", "Garden", "Bicycle"]),
        WordSet(prompt: "Bathroom",  correct: ["Towel", "Soap", "Mirror"],    distractors: ["Hammer", "Tree", "Book"]),
        WordSet(prompt: "Garden",    correct: ["Flower", "Shovel", "Hose"],   distractors: ["Lamp", "Phone", "Wallet"]),
        WordSet(prompt: "School",    correct: ["Pencil", "Teacher", "Desk"],  distractors: ["Stove", "Tire", "Blanket"]),
        WordSet(prompt: "Hospital",  correct: ["Doctor", "Medicine", "Bed"],  distractors: ["Football", "Guitar", "Paint"]),
        WordSet(prompt: "Beach",     correct: ["Sand", "Waves", "Umbrella"],  distractors: ["Clock", "Hammer", "Carpet"]),
        WordSet(prompt: "Office",    correct: ["Computer", "Chair", "Printer"], distractors: ["Stove", "Shovel", "Pillow"]),
        WordSet(prompt: "Music",     correct: ["Piano", "Guitar", "Drums"],   distractors: ["Spoon", "Towel", "Ladder"]),
    ]

    @Published var currentPhase: WordAssociationPhase = .instruction
    @Published var currentRound: Int = 0
    @Published var score: Int = 0
    @Published var options: [WordOption] = []
    @Published var promptWord: String = ""

    private var shuffledSets: [WordSet] = []
    private var totalRounds: Int = 0
    private var sessionStartedAt = Date()
    private var hasSubmittedSession = false
    private var totalCorrectSelections = 0
    private var totalIncorrectSelections = 0
    private var totalMissedSelections = 0

    var currentSetIndex: Int { currentRound - 1 }
    var isLastRound: Bool { currentRound >= totalRounds }

    // MARK: - Game Control

    func startGame() {
        AnalyticsManager.shared.logEvent(name: AnalyticsManager.Events.gameStart, parameters: [
            AnalyticsManager.Parameters.gameType: "WordAssociation"
        ])
        score = 0
        currentRound = 0
        shuffledSets = allWordSets.shuffled()
        totalRounds = shuffledSets.count
        sessionStartedAt = Date()
        hasSubmittedSession = false
        totalCorrectSelections = 0
        totalIncorrectSelections = 0
        totalMissedSelections = 0
        withAnimation { currentPhase = .playing }
        nextRound()
    }

    func nextRound() {
        currentRound += 1
        guard currentRound <= totalRounds else {
            withAnimation { currentPhase = .completed }
            return
        }
        let wordSet = shuffledSets[currentRound - 1]
        promptWord = wordSet.prompt
        let allWords = (wordSet.correct + wordSet.distractors).shuffled()
        options = allWords.map { WordOption(word: $0) }
        withAnimation { currentPhase = .playing }
    }

    func toggleWord(_ option: WordOption) {
        guard currentPhase == .playing else { return }
        HapticManager.shared.trigger(.selection)
        if let index = options.firstIndex(where: { $0.id == option.id }) {
            options[index].isSelected.toggle()
        }
    }

    func submitAnswer() {
        guard currentPhase == .playing else { return }
        let wordSet = shuffledSets[currentRound - 1]
        let correctWords = Set(wordSet.correct)

        var roundScore = 0
        for i in options.indices {
            let isCorrect = correctWords.contains(options[i].word)
            if options[i].isSelected && isCorrect {
                options[i].feedbackState = .correct
                roundScore += 10
                totalCorrectSelections += 1
            } else if options[i].isSelected && !isCorrect {
                options[i].feedbackState = .incorrect
                roundScore -= 5
                totalIncorrectSelections += 1
            } else if !options[i].isSelected && isCorrect {
                options[i].feedbackState = .missed
                totalMissedSelections += 1
            } else {
                options[i].feedbackState = .none
            }
        }
        score += max(0, roundScore)

        if roundScore > 0 {
            HapticManager.shared.trigger(.success)
        } else {
            HapticManager.shared.trigger(.error)
        }

        withAnimation { currentPhase = .feedback }
    }

    func continueAfterFeedback() {
        if isLastRound {
            finishSession()
        } else {
            nextRound()
        }
    }

    func restartGame() {
        startGame()
    }

    // MARK: - Computed Stats

    var accuracy: Int {
        let totalOpportunities = totalRounds * 3
        guard totalOpportunities > 0 else { return 0 }
        return min(100, Int((Double(totalCorrectSelections) / Double(totalOpportunities)) * 100))
    }

    var roundProgress: String { "\(currentRound) / \(totalRounds)" }

    private func finishSession() {
        withAnimation { currentPhase = .completed }
        AnalyticsManager.shared.logEvent(name: AnalyticsManager.Events.gameComplete, parameters: [
            AnalyticsManager.Parameters.gameType: "WordAssociation",
            AnalyticsManager.Parameters.score: score
        ])
        Task { @MainActor in
            await submitSessionIfNeeded(outcome: .completed, completed: true)
        }
    }

    func handleViewDisappeared() {
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

        let request = GameSessionSubmissionBuilder(
            gameType: .wordAssociation,
            score: score,
            durationSeconds: Int(Date().timeIntervalSince(sessionStartedAt)),
            startedAt: sessionStartedAt,
            completedAt: Date(),
            outcome: outcome,
            completed: completed,
            levelReached: totalRounds,
            accuracy: Double(accuracy),
            mistakes: totalIncorrectSelections + totalMissedSelections,
            difficulty: "standard",
            metadata: [
                "exitPhase": "\(currentPhase)",
                "completed": "\(completed)",
                "roundsCompleted": "\(totalRounds)",
                "correctSelections": "\(totalCorrectSelections)",
                "incorrectSelections": "\(totalIncorrectSelections)",
                "missedSelections": "\(totalMissedSelections)",
            ]
        ).makeRequest(documentId: documentId)

        do {
            try await GameSessionService.shared.submitSession(request)
        } catch {
            print("Failed to submit Word Link session: \(error)")
        }
    }
}
