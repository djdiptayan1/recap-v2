//
//  memoryQuizModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI

struct QuizQuestion: Identifiable, Codable {
    let id: String
    let question: String
    let order: Int
    let correctAnswer: Bool
}

struct QuizResponse: Codable {
    let success: Bool
    let data: [QuizQuestion]
}

struct QuizResult {
    let score: Int
    let totalQuestions: Int
    let title: String
    let description: String
    let color: Color
    let icon: String
}

struct QuizSubmissionRequest: Codable {
    let documentId: String
    let score: Int
}

struct QuizSubmissionResponse: Codable {
    let success: Bool
    let message: String
    let data: QuizSubmissionData
}

struct QuizSubmissionData: Codable {
    let reportId: String
    let totalScore: Int
    let totalQuestions: Int
    let overallPercentage: Double
    let status: String
    let recommendations: [String]
    let color: String
    let icon: String
    let result: QuizResultDescription
    
    var swiftColor: Color {
        switch color.lowercased() {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

struct QuizResultDescription: Codable {
    let status: String
    let description: String
    let color: String
    let icon: String
}
