//
//  GameSessionModels.swift
//  recap
//

import Foundation

enum RecapGameType: String, Codable, CaseIterable, Identifiable {
    case dailyObjects
    case matchMania
    case numberBubbles
    case wordAssociation
    case patternMemory

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dailyObjects: return "Daily Objects"
        case .matchMania: return "Match Mania"
        case .numberBubbles: return "Number Bubbles"
        case .wordAssociation: return "Word Link"
        case .patternMemory: return "Pattern Memory"
        }
    }
}

enum GameSessionOutcome: String, Codable {
    case completed
    case timeout
    case livesExhausted = "lives_exhausted"
}

struct GameSessionRequest: Codable {
    let documentId: String
    let gameType: String
    let score: Int
    let durationSeconds: Int
    let startedAt: String
    let completedAt: String
    let outcome: String
    let completed: Bool
    let levelReached: Int?
    let accuracy: Double?
    let mistakes: Int
    let difficulty: String?
    let metadata: [String: String]
}

struct GameSessionResponse: Codable {
    let success: Bool
    let message: String
}

struct GameAnalyticsResponse: Codable {
    let success: Bool
    let data: GameAnalyticsData
}

struct GameAnalyticsData: Codable {
    let overall: GameOverallSummary
    let byGame: [GameAggregate]
    let trend: [GameTrendPoint]
    let recentSessions: [RecentGameSession]
}

struct GameOverallSummary: Codable {
    let sessionsLast7Days: Int
    let sessionsLast30Days: Int
    let averageScore: Double
    let averageAccuracy: Double
    let averageDurationSeconds: Double
    let favoriteGame: String?
    let lastPlayedAt: String?
}

struct GameAggregate: Codable, Identifiable {
    var id: String { gameType }

    let gameType: String
    let sessions: Int
    let averageScore: Double
    let averageAccuracy: Double
    let bestScore: Int
    let averageDurationSeconds: Double
    let lastPlayedAt: String?

    var displayName: String {
        RecapGameType(rawValue: gameType)?.displayName ?? gameType
    }
}

struct GameTrendPoint: Codable, Identifiable {
    var id: String { date }

    let date: String
    let label: String
    let sessions: Int
    let averageScore: Double
    let averageAccuracy: Double
}

struct RecentGameSession: Codable, Identifiable {
    let id: String
    let gameType: String
    let score: Int
    let durationSeconds: Int
    let startedAt: String?
    let completedAt: String?
    let outcome: String
    let completed: Bool
    let levelReached: Int?
    let accuracy: Double?
    let mistakes: Int
    let difficulty: String?
    let metadata: [String: String]?

    var displayName: String {
        RecapGameType(rawValue: gameType)?.displayName ?? gameType
    }

    var completedDateLabel: String {
        guard
            let completedAt,
            let date = ISO8601DateFormatter.withFractionalSeconds.date(from: completedAt)
                ?? ISO8601DateFormatter().date(from: completedAt)
        else {
            return "Just now"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
