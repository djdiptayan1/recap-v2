//
//  AddQuestionsViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/01/26.
//

import Foundation
import Combine

class AddQuestionsViewModel: ObservableObject {
    @Published var questionText: String = ""
    @Published var answerOptions: [String] = ["", ""] // Start with 2 empty options
    @Published var correctAnswers: [String] = []
    @Published var hint: String = ""
    @Published var category: String = "Personal"
    @Published var subCategory: String = "Memory"
    @Published var startTime: Date = Date()
    @Published var endTime: Date = Date().addingTimeInterval(86400 * 30) // Default 30 days
    @Published var frequency: String = "1"
    
    // Legacy support (if needed) or mapped properties
    var tag: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSuccess: Bool = false
    
    let categories = ["Personal", "General"]
    let subCategories = ["Memory", "Preference", "Fact", "Story"]
    
    // MARK: - API Models
    
    struct AddQuestionRequest: Codable {
        let text: String
        let answerOptions: [String]
        let category: String
        let timeFrame: QuestionTimeFrame
        let askInterval: Int
        let tag: String
        let questionType: String
        let subcategory: String
        let correctAnswers: [String]
        let hint: String
    }

    struct QuestionTimeFrame: Codable {
        let from: String
        let to: String
    }

    struct AddQuestionResponse: Codable {
        let success: Bool
        let message: String
    }
    
    // MARK: - API Endpoint
    
    private enum QuestionsAPI: Endpoint {
        case addQuestion(patientID: String, data: AddQuestionRequest)
        
        var path: String {
            switch self {
            case .addQuestion(let patientID, _):
                return "\(AppConfig.ApiEndpoints.familyQuestions)/\(patientID)/add"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .addQuestion:
                return .post
            }
        }
        
        var body: Encodable? {
            switch self {
            case .addQuestion(_, let data):
                return data
            }
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
    // MARK: - Actions
    
    func addOption() {
        answerOptions.append("")
    }
    
    func removeOption(at index: Int) {
        if answerOptions.count > 1 {
            let optionToRemove = answerOptions[index]
            correctAnswers.removeAll { $0 == optionToRemove } // Ensure it's not marked correct anymore
            answerOptions.remove(at: index)
        }
    }
    
    @MainActor
    func submitQuestion(patientID: String) async {
        guard !questionText.isEmpty else {
            errorMessage = "Question text is required"
            return
        }
        
        let validOptions = answerOptions.filter { !$0.isEmpty }
        guard validOptions.count >= 1 else {
            errorMessage = "At least one answer option is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        isSuccess = false
        
        // Format dates
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let timeFrame = QuestionTimeFrame(
            from: formatter.string(from: startTime),
            to: formatter.string(from: endTime)
        )
        
        let request = AddQuestionRequest(
            text: questionText,
            answerOptions: validOptions,
            category: category,
            timeFrame: timeFrame,
            askInterval: Int(frequency) ?? 1,
            tag: tag.isEmpty ? category : tag,
            questionType: "MultiChoice",
            subcategory: subCategory,
            correctAnswers: correctAnswers,
            hint: hint
        )
        
        do {
            let _: AddQuestionResponse = try await NetworkManager.shared.request(endpoint: QuestionsAPI.addQuestion(patientID: patientID, data: request))
             // Assuming success if no error thrown and decoding works (NetworkManager usually throws on non-200)
            isSuccess = true
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
            print("Error adding question: \(error)")
        }
        
        isLoading = false
    }
    
    func resetForm() {
        questionText = ""
        answerOptions = ["", ""]
        correctAnswers = []
        hint = ""
        category = "Personal"
        subCategory = "Memory"
        startTime = Date()
        endTime = Date().addingTimeInterval(86400 * 30)
        frequency = "1"
        tag = ""
    }
}
