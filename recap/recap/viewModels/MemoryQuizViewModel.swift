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
    
    @Published var isSubmitting = false
    @Published var isProcessingAnswer = false
    var apiResult: QuizSubmissionData?
    
    // Remove stored documentID property since we fetch it from Keychain
    
    // Remove init with documentID
    
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
                await MainActor.run {
                    self.questions = response.data.sorted { $0.order < $1.order }
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch questions"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            print("Error fetching questions: \(error)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func submitAnswer(isTrue: Bool) {
        guard !isProcessingAnswer else { return }
        isProcessingAnswer = true
        
        guard currentIndex < questions.count else { return }
        let currentQuestion = questions[currentIndex]
        
        if isTrue == currentQuestion.correctAnswer {
            trueAnswersCount += 1
        }
        
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.isProcessingAnswer = false
                }
            }
        } else {
            Task {
                await submitQuiz()
            }
        }
    }
    
    func submitQuiz() async {
        await MainActor.run { isSubmitting = true }
        
        guard let documentID = KeychainManager.shared.getString(key: .documentID) else {
            await MainActor.run {
                self.errorMessage = "User not authenticated (ID not found)"
                self.isSubmitting = false
            }
            return
        }
        
        print("Submitting quiz result for documentID: \(documentID) with score: \(trueAnswersCount)")
        let request = QuizSubmissionRequest(documentId: documentID, score: Int(trueAnswersCount))
        
        do {
            let response: QuizSubmissionResponse = try await NetworkManager.shared.request(
                endpoint: MemoryQuizAPI.submitResult(request: request)
            )
            
            await MainActor.run {
                if response.success {
                    self.apiResult = response.data
                    self.isCompleted = true
                } else {
                    self.errorMessage = response.message
                }
                self.isSubmitting = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSubmitting = false
            }
        }
    }
    
    func getResult() -> QuizResult {
        if let data = apiResult {
            return QuizResult(
                score: data.totalScore,
                totalQuestions: data.totalQuestions,
                title: data.result.status,
                description: data.result.description,
                color: data.swiftColor,
                icon: data.result.icon
            )
        }
        
        // Fallback for initial state or error (should not be shown if isCompleted is managed correctly)
        return QuizResult(
            score: trueAnswersCount,
            totalQuestions: questions.count,
            title: "Processing...",
            description: "Please wait while we analyze your results.",
            color: .gray,
            icon: "hourglass"
        )
    }
    
    func restart() {
        currentIndex = 0
        trueAnswersCount = 0
        isCompleted = false
        isSubmitting = false
        apiResult = nil
    }
}

private enum MemoryQuizAPI: Endpoint {
    case getQuestions
    case submitResult(request: QuizSubmissionRequest)
    
    var path: String {
        switch self {
        case .getQuestions, .submitResult:
            return AppConfig.ApiEndpoints.memoryQuiz
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getQuestions:
            return .get
        case .submitResult:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .getQuestions:
            return nil
        case .submitResult(let request):
            return request
        }
    }
}
