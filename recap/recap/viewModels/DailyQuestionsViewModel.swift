//
//  DailyQuestionsViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 10/12/25.
//

import SwiftUI
import Combine

class DailyQuestionsViewModel: ObservableObject {
    @Published var questions: [QuestionModel] = []
    @Published var currentIndex = 0
    @Published var isCompleted = false
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private enum QuestionAPI: Endpoint {
        case fetch
        
        var path: String {
            return AppConfig.ApiEndpoints.getDailyQuestions
        }
        
        var method: HTTPMethod { .get }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
    var progress: CGFloat {
        guard !questions.isEmpty else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(questions.count)
    }
    
    // Current question to display
    var currentQuestion: QuestionModel? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    init() {
        fetchQuestions()
    }
    
    func fetchQuestions() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let response = try await NetworkManager.shared.request(
                    endpoint: QuestionAPI.fetch,
                    responseType: QuestionResponse.self,
                    keyDecodingStrategy: .useDefaultKeys
                )
                self.questions = response.data
                self.isLoading = false
            } catch {
                print("Error fetching questions: \(error)")
                self.errorMessage = "Failed to load questions"
                self.isLoading = false
            }
        }
    }
    
    func submitAnswer(_ answer: String) {
        // Logic to save answer can go here (e.g., send to backend)
        print("Selected Answer: \(answer) for Question: \(currentQuestion?.text ?? "")")
        
        // Move to next
        withAnimation {
            if currentIndex < questions.count - 1 {
                currentIndex += 1
            } else {
                isCompleted = true
            }
        }
    }
}
