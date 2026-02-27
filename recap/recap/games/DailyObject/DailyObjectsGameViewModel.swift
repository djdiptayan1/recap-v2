//
//  DailyObjectsGameViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

struct DailyObject: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    var color: Color = AppConfig.Colors.accent
}

enum GamePhase {
    case instruction
    case memorizing
    case recalling
    case roundSummary
}

// MARK: - ViewModel

class DailyObjectsGameViewModel: ObservableObject {
    // Game Config
    private let allObjects: [DailyObject] = [
        DailyObject(name: "House", icon: "house.fill", color: .blue),
        DailyObject(name: "Phone", icon: "phone.fill", color: .green),
        DailyObject(name: "Keys", icon: "key.fill", color: .orange),
        DailyObject(name: "Glasses", icon: "eyeglasses", color: .purple),
        DailyObject(name: "Medicine", icon: "pills.fill", color: .red),
        DailyObject(name: "Cup", icon: "cup.and.saucer.fill", color: .brown),
        DailyObject(name: "Book", icon: "book.fill", color: .blue),
        DailyObject(name: "Clock", icon: "clock.fill", color: .gray),
        DailyObject(name: "Wallet", icon: "creditcard.fill", color: .black),
        DailyObject(name: "Lamp", icon: "lamp.desk.fill", color: .yellow),
        DailyObject(name: "Umbrella", icon: "umbrella.fill", color: .teal),
        DailyObject(name: "Bag", icon: "bag.fill", color: .indigo),
    ]

    // Published States
    @Published var currentPhase: GamePhase = .instruction
    @Published var currentRound: Int = 1
    @Published var score: Int = 0
    @Published var objectsToMemorize: [DailyObject] = []
    @Published var recallGridObjects: [DailyObject] = []  // Mix of correct + distractors
    @Published var selectedIDs: Set<UUID> = []

    // Timer State
    @Published var timeRemaining: CGFloat = 1.0  // 0.0 to 1.0 progress
    @Published var timerString: String = "10"
    private var timer: Timer?
    private var initialTime: TimeInterval = 10.0

    // Settings
    private var objectsPerRound: Int = 3

    // MARK: - Game Control

    func startGame() {
        score = 0
        currentRound = 1
        objectsPerRound = 3
        startRound()
    }

    func startRound() {
        // 1. Pick random objects
        objectsToMemorize = Array(allObjects.shuffled().prefix(objectsPerRound))

        // 2. Reset Timer
        currentPhase = .memorizing
        startMemorizeTimer()
    }

    func startRecallPhase() {
        timer?.invalidate()

        // 1. Prepare Distractors
        let correctSet = Set(objectsToMemorize.map { $0.id })
        let distractors = allObjects.filter { !correctSet.contains($0.id) }
        let numDistractors = max(2, objectsPerRound - 1)
        let selectedDistractors = Array(distractors.shuffled().prefix(numDistractors))

        // 2. Mix and Shuffle
        recallGridObjects = (objectsToMemorize + selectedDistractors).shuffled()
        selectedIDs.removeAll()

        // 3. Transition
        withAnimation {
            currentPhase = .recalling
        }
    }

    func toggleSelection(_ object: DailyObject) {
        if selectedIDs.contains(object.id) {
            selectedIDs.remove(object.id)
        } else {
            // Haptic Feedback
            HapticManager.shared.trigger(.light)
            selectedIDs.insert(object.id)
        }
    }

    func submitAnswers() {
        let correctIDs = Set(objectsToMemorize.map { $0.id })

        // Simple Scoring: Correct * 10 - Incorrect * 5
        let correctPicks = selectedIDs.intersection(correctIDs).count
        let incorrectPicks = selectedIDs.subtracting(correctIDs).count

        let roundScore = max(0, (correctPicks * 10) - (incorrectPicks * 5))
        score += roundScore

        // Difficulty Progression
        if correctPicks == objectsPerRound && incorrectPicks == 0 {
            // Perfect round, increase difficulty every 2 rounds
            if currentRound % 2 == 0 { objectsPerRound = min(objectsPerRound + 1, 6) }
        }

        withAnimation {
            currentPhase = .roundSummary
        }
    }

    func nextRound() {
        currentRound += 1
        startRound()
    }

    // MARK: - Timer Logic

    private func startMemorizeTimer() {
        var duration = initialTime + Double(currentRound)  // Give more time as rounds get harder
        let totalDuration = duration

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            duration -= 0.1

            withAnimation(.linear(duration: 0.1)) {
                self.timeRemaining = CGFloat(duration / totalDuration)
                self.timerString = String(format: "%.0f", ceil(duration))
            }

            if duration <= 0 {
                self.startRecallPhase()
            }
        }
    }
}
