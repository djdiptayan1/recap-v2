//
//  StreakModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/12/25.
//

import Foundation

// MARK: - Stats Response
struct StreakStatsResponse: Codable {
    let success: Bool
    let data: StreakStatsData
}

struct StreakStatsData: Codable {
    let lastAnswered: FirestoreTimestamp?
    let longestBreak: Int?
    let activeDays: Int
    let correctAnswers: Int?
    let totalQuestionsAnswered: Int?
    let answeredToday: Bool
    let currentStreak: Int
    let lastAnsweredDate: String?
    let maxStreak: Int
    let initialized: Bool?
}

struct FirestoreTimestamp: Codable, Equatable {
    let type: String
    let seconds: Int
    let nanoseconds: Int
    
//    enum CodingKeys: String, CodingKey {
//        case type
//        case seconds
//        case nanoseconds
//    }
}

// MARK: - Year Response
struct StreakYearResponse: Codable {
    let success: Bool
    let data: [String: [String: Bool]] // Key: "YYYY-MM", Value: ["YYYY-MM-DD": Bool]
}

// MARK: - Month Response
struct StreakMonthResponse: Codable {
    let success: Bool
    let data: [String: Bool] // Key: "YYYY-MM-DD", Value: Bool
}
