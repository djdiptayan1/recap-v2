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
    let userIdentifier: String
}

struct SmritiContext: Codable {
    let patientName: String?
    let stage: String?
    let dob: String?
    let familyMembers: [SmritiFamilyMember]?
    let recentActivities: SmritiActivities?
    let mode: String?  // "care" or "memoryLane"
}

struct SmritiActivities: Codable {
    let streakDays: Int?
    let reminders: [String]?
}

struct SmritiFamilyMember: Codable {
    let name: String
    let relation: String
}

struct SmritiHistoryMessage: Codable {
    let role: String
    let text: String
}

// MARK: - API Response (structured endpoint)
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

// MARK: - Usage Response (rate limiting)
struct SmritiUsageResponse: Codable {
    let dailyRemaining: Int
    let weeklyRemaining: Int
    let dailyLimit: Int
    let weeklyLimit: Int
    let nextDailyReset: String?
    let nextWeeklyReset: String?
    let aiProvider: String
}

// MARK: - Rate Limit Error Response
struct SmritiRateLimitError: Codable {
    let error: String
    let message: String
    let dailyRemaining: Int
    let weeklyRemaining: Int
    let dailyLimit: Int
    let weeklyLimit: Int
    let resetAt: String?
    let aiProvider: String
}
