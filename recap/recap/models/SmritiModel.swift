//
//  SmritiModel.swift
//  recap
//
//  Created by Diptayan Jash on 08/01/26.
//

import Foundation

// MARK: - API Request
struct SmritiRequest: Codable {
    let query: String
    let context: SmritiContext?
    let history: [SmritiHistoryMessage]?
}

struct SmritiContext: Codable {
    let patientName: String?
    let stage: String?
    let familyMembers: [SmritiFamilyMember]?
}

struct SmritiFamilyMember: Codable {
    let name: String
    let relation: String
}

struct SmritiHistoryMessage: Codable {
    let role: String
    let text: String
}

// MARK: - API Response
struct SmritiResponse: Codable {
    let summary: String?
    let answer: String
    let care_strategies: [String]?
    let medical_disclaimer: String?
    let sources: [SmritiSource]?
    let supportive_note: String?
    let followup_prompt: String?
}

struct SmritiSource: Codable, Hashable {
    let name: String
    let url: String
}
