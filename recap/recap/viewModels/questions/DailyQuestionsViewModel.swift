//
//  DailyQuestionsViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 10/12/25.
//

import Combine
import SwiftUI

class DailyQuestionsViewModel: ObservableObject {
    @Published var questions: [QuestionModel] = []
    @Published var currentIndex = 0
    @Published var isCompleted = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let patientId: String

    private enum QuestionAPI: Endpoint {
        case fetch(patientId: String)
        case answer(AnswerRequest)

        var path: String {
            switch self {
            case .fetch: return AppConfig.ApiEndpoints.getDailyQuestions
            case .answer: return AppConfig.ApiEndpoints.answerDailyQuestion
            }
        }

        var method: HTTPMethod {
            switch self {
            case .fetch: return .get
            case .answer: return .post
            }
        }

        var queryItems: [URLQueryItem]? {
            switch self {
            case .fetch(let patientId):
                return [URLQueryItem(name: "patientId", value: patientId)]
            default: return nil
            }
        }

        var body: Encodable? {
            switch self {
            case .answer(let request):
                return request
            default: return nil
            }
        }
    }

    struct AnswerRequest: Encodable {
        let patientId: String
        let questionId: String
        // Using [String] to support multiple answers; JSONEncoder handles array encoding naturally.
        let answer: [String]
        let answeredBy: String
        let date: String
        let category: String
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

    init(patientId: String) {
        self.patientId = patientId
    }

    func loadQuestions(role: String) {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            // Use prefetched data if available
            if let cached = DataPrefetchManager.shared.dailyQuestions {
                let allQuestions = cached.data
                if role == "patient" {
                    self.questions = allQuestions.filter { !($0.isAnswered ?? false) }
                } else {
                    self.questions = allQuestions.filter { ($0.correctAnswers ?? []).isEmpty }
                }
                if self.questions.isEmpty {
                    self.isCompleted = true
                }
                self.isLoading = false
                return
            }

            do {
                let response = try await NetworkManager.shared.request(
                    endpoint: QuestionAPI.fetch(patientId: patientId),
                    responseType: QuestionResponse.self,
                    keyDecodingStrategy: .useDefaultKeys
                )

                let allQuestions = response.data

                // Filter questions based on role
                if role == "patient" {
                    self.questions = allQuestions.filter { !($0.isAnswered ?? false) }
                } else {
                    // Family: verify/answer questions that have no correct answers yet
                    self.questions = allQuestions.filter { ($0.correctAnswers ?? []).isEmpty }
                }

                if self.questions.isEmpty {
                    self.isCompleted = true
                }

                self.isLoading = false
            } catch {
                print("Error fetching questions: \(error)")
                self.errorMessage = "Failed to load questions"
                self.isLoading = false
            }
        }
    }

    func submitAnswer(_ answer: [String], answeredBy: String) {
        guard let question = currentQuestion else { return }

        // Invalidate cached questions and streak stats since answers change the data
        DataPrefetchManager.shared.invalidateDailyQuestions()
        DataPrefetchManager.shared.invalidateStreakStats()

        let request = AnswerRequest(
            patientId: patientId,
            questionId: question.id,
            answer: answer,
            answeredBy: answeredBy,
            date: question.assignedDate ?? "",
            category: question.category
        )

        Task {  // Fire and forget (or handle error if needed, but for UX likely just proceed)
            do {
                _ = try await NetworkManager.shared.request(
                    endpoint: QuestionAPI.answer(request),
                    responseType: EmptyResponse.self  // Assuming simple success response, or define a specific one
                )
                print("Answer submitted successfully")
            } catch {
                print("Error submitting answer: \(error)")
            }
        }

        print("Selected Answer: \(answer) for Question: \(question.text)")

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

struct EmptyResponse: Decodable {}
