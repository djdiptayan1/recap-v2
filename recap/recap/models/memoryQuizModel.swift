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

struct TypeScore: Codable {
    let memoryType: String?
    let total: Int?
    let correct: Int?
}

struct MemoryReport: Codable, Identifiable {
    let id: String
    let date: String

    let status: String?
    let totalScore: Int?
    let totalQuestions: Int?
    let overallPercentage: Double?

    let color: String?
    let icon: String?
    let recommendations: [String]?
    let typeScores: [TypeScore]?

    enum CodingKeys: String, CodingKey {
        case id, date, status, totalScore, totalQuestions
        case overallPercentage, color, icon, recommendations, typeScores
    }

    var swiftColor: Color {
        switch color?.lowercased() {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let dateObj = formatter.date(from: date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "d MMM yyyy 'at' h:mm a"
            return displayFormatter.string(from: dateObj)
        }
        return date
    }
}

struct MemoryReportsResponse: Codable {
    let success: Bool
    let data: [MemoryReport]

    enum CodingKeys: String, CodingKey {
        case success, data
    }
}

extension MemoryReport {
    var safeStatus: String {
        status ?? "Unknown Status"
    }

    var safeTotalScore: Int {
        totalScore ?? 0
    }

    var safeTotalQuestions: Int {
        totalQuestions ?? 0
    }

    var safeIcon: String {
        icon ?? "brain.head.profile"
    }
}
