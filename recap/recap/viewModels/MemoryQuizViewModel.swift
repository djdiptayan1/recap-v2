//
//  MemoryQuizViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI
import Combine

class MemoryQuizViewModel: ObservableObject {
    @Published var questions: [QuizQuestion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var currentIndex = 0
    @Published var trueAnswersCount = 0
    @Published var isCompleted = false
    
    var progress: CGFloat {
        guard !questions.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(questions.count)
    }
    
    func fetchQuestions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: QuizResponse = try await NetworkManager.shared.request(endpoint: MemoryQuizAPI.getQuestions)
            if response.success {
                self.questions = response.data.sorted { $0.order < $1.order }
            } else {
                self.errorMessage = "Failed to fetch questions"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching questions: \(error)")
        }
        
        isLoading = false
    }
    
    func submitAnswer(isTrue: Bool) {
        if isTrue {
            trueAnswersCount += 1
        }
        
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            withAnimation {
                isCompleted = true
            }
        }
    }
    
    func getResult() -> QuizResult {
        switch trueAnswersCount {
        case 0...8:
            return QuizResult(
                score: trueAnswersCount,
                title: "Functioning Okay",
                description: "Your brain is functioning okay. By learning to relax and maintain a healthy diet, your brain can function at even higher levels.",
                color: Color.green,
                icon: "brain.head.profile"
            )
        case 9...11:
            return QuizResult(
                score: trueAnswersCount,
                title: "Brain in Danger",
                description: "Your brain is in danger. Check your diet today. You can reduce brain drain and memory loss with vitamins, brain foods, herbs, yoga and meditation techniques, and appropriate medications.",
                color: Color.orange,
                icon: "exclamationmark.triangle.fill"
            )
        default: // 12-15
            return QuizResult(
                score: trueAnswersCount,
                title: "Running on Empty",
                description: "Your brain is running on empty. You should see your doctor. You can refuel your brain and prevent further memory loss with food, vitamins, herbs, exercises, and medications.",
                color: Color.red,
                icon: "battery.0.percent"
            )
        }
    }
    
    func restart() {
        currentIndex = 0
        trueAnswersCount = 0
        isCompleted = false
    }
}

private enum MemoryQuizAPI: Endpoint {
    case getQuestions
    
    var path: String {
        switch self {
        case .getQuestions:
            return AppConfig.ApiEndpoints.memoryQuiz
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getQuestions:
            return .get
        }
    }
}
