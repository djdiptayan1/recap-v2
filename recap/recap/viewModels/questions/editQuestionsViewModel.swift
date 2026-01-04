//
//  editQuestionsViewModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class EditQuestionsViewModel: ObservableObject {
    @Published var questions: [QuestionModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    // MARK: - API Endpoints
    private enum EditQuestionsAPI: Endpoint {
        case getQuestions(patientID: String)
        case updateQuestion(patientID: String, questionID: String, data: EditQuestionRequest)
        case deleteQuestion(patientID: String, questionID: String)
        
        var path: String {
            switch self {
            case .getQuestions(let patientID):
                return "\(AppConfig.ApiEndpoints.familyQuestions)/\(patientID)"
            case .updateQuestion(let patientID, let questionID, _):
                return "\(AppConfig.ApiEndpoints.familyQuestions)/\(patientID)/edit/\(questionID)"
            case .deleteQuestion(let patientID, let questionID):
                return "\(AppConfig.ApiEndpoints.familyQuestions)/\(patientID)/delete/\(questionID)"
            }
        }
        
        var method: HTTPMethod {
            switch self {
            case .getQuestions:
                return .get
            case .updateQuestion:
                return .put
            case .deleteQuestion:
                return .delete
            }
        }
        
        var body: Encodable? {
            switch self {
            case .getQuestions, .deleteQuestion:
                return nil
            case .updateQuestion(_, _, let data):
                return data
            }
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
    
    // MARK: - Models
    struct EditQuestionRequest: Codable {
        let text: String
        let answerOptions: [String]
        let category: String
        let subcategory: String
        let correctAnswers: [String]?
        let hint: String?
        let isActive: Bool?
    }
    
    struct GetAllQuestionsResponse: Codable {
        let success: Bool
        let data: [QuestionModel]
    }
    
    struct UpdateQuestionResponse: Codable {
        let success: Bool
        let message: String
    }
    
    struct DeleteQuestionResponse: Codable {
        let success: Bool
        let message: String
    }
    
    // MARK: - Actions
    
    func fetchQuestions(patientID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: GetAllQuestionsResponse = try await NetworkManager.shared.request(endpoint: EditQuestionsAPI.getQuestions(patientID: patientID))
            if response.success {
                self.questions = response.data
            } else {
                self.errorMessage = "Failed to fetch questions"
            }
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error fetching questions: \(error)")
        }
        
        isLoading = false
    }
    
    func updateQuestion(patientID: String, question: QuestionModel, newText: String, newOptions: [String], correctAnswers: [String]?, hint: String?, isActive: Bool?) async {
        isLoading = true
        errorMessage = nil
        isSuccess = false
        
        let validOptions = newOptions.filter { !$0.isEmpty }
        guard !newText.isEmpty, validOptions.count >= 2 else {
            errorMessage = "Question text and at least 2 options are required."
            isLoading = false
            return
        }
        
        let request = EditQuestionRequest(
            text: newText,
            answerOptions: validOptions,
            category: question.category,
            subcategory: question.subcategory,
            correctAnswers: correctAnswers,
            hint: hint,
            isActive: isActive
        )
        
        do {
            let response: UpdateQuestionResponse = try await NetworkManager.shared.request(
                endpoint: EditQuestionsAPI.updateQuestion(patientID: patientID, questionID: question.id, data: request)
            )
            
            if response.success {
                isSuccess = true
                await fetchQuestions(patientID: patientID) // Refresh list
            } else {
                errorMessage = response.message
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error updating question: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteQuestion(patientID: String, questionID: String) async {
        isLoading = true
        errorMessage = nil
        // Do not set isSuccess = false here if we want to distinguish delete from update, OR use isSuccess but handle dismissal differently
        
        do {
            let response: DeleteQuestionResponse = try await NetworkManager.shared.request(endpoint: EditQuestionsAPI.deleteQuestion(patientID: patientID, questionID: questionID))
            
            if response.success {
                // Remove locally to update UI immediately
                self.questions.removeAll { $0.id == questionID }
                isSuccess = true 
            } else {
                errorMessage = response.message
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting question: \(error)")
        }
        
        isLoading = false
    }
}
