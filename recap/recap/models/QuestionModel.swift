//
//  QuestionModel.swift
//  recap
//
//  Created by Diptayan Jash on 10/12/25.
//

import Foundation

struct QuestionResponse: Codable {
    let success: Bool
    let count: Int
    let data: [QuestionModel]
    let meta: MetaData
}

struct MetaData: Codable {
    let immediate: Int
    let recent: Int
    let remote: Int
}

struct QuestionModel: Codable, Identifiable {
    let id: String
    let text: String
    let answerOptions: [String]
    let hint: String?
    let category: String // "immediateMemory", "recentMemory", etc.
    let subcategory: String // "nutrition", "socialInteraction", etc.
    let questionType: String // "multipleChoice", "yesNo"
    
    // Additional fields
    let hardness: Int?
    let priority: Int?
    let isActive: Bool?
    let isAnswered: Bool?
    
    // Use coding keys to map JSON keys safely if needed,
    // but your JSON keys match these property names well.
}
