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
    let title: String
    let description: String
    let color: Color
    let icon: String
}
