//
//  memoryQuizModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI

struct QuizQuestion: Identifiable {
    let id = UUID()
    let text: String
}

struct QuizResult {
    let score: Int
    let title: String
    let description: String
    let color: Color
    let icon: String
}
