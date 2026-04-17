import Foundation
import SwiftUI

enum DailyMoodKey: String, CaseIterable, Codable, Identifiable {
    case veryUnpleasant = "very_unpleasant"
    case unpleasant = "unpleasant"
    case neutral = "neutral"
    case pleasant = "pleasant"
    case veryPleasant = "very_pleasant"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .veryUnpleasant: return "Very Unpleasant"
        case .unpleasant: return "Unpleasant"
        case .neutral: return "Neutral"
        case .pleasant: return "Pleasant"
        case .veryPleasant: return "Very Pleasant"
        }
    }

    var score: Double {
        switch self {
        case .veryUnpleasant: return 0
        case .unpleasant: return 1
        case .neutral: return 2
        case .pleasant: return 3
        case .veryPleasant: return 4
        }
    }

    var summaryCopy: String {
        switch self {
        case .veryUnpleasant: return "A difficult day was logged."
        case .unpleasant: return "A low mood was logged today."
        case .neutral: return "Today feels balanced."
        case .pleasant: return "Today is trending positive."
        case .veryPleasant: return "A very positive day was logged."
        }
    }

    var palette: MoodPalette {
        switch self {
        case .veryUnpleasant:
            return MoodPalette(
                primary: Color(hex: "#A66CFF"),
                secondary: Color(hex: "#5B31C9"),
                glow: Color(hex: "#C8A8FF"),
                backgroundTop: Color(hex: "#2B293B"),
                backgroundBottom: Color(hex: "#1B1A27")
            )
        case .unpleasant:
            return MoodPalette(
                primary: Color(hex: "#7D9BFF"),
                secondary: Color(hex: "#2D56E0"),
                glow: Color(hex: "#B7CAFF"),
                backgroundTop: Color(hex: "#343B4B"),
                backgroundBottom: Color(hex: "#242B38")
            )
        case .neutral:
            return MoodPalette(
                primary: Color(hex: "#A7E4FF"),
                secondary: Color(hex: "#66BCE8"),
                glow: Color(hex: "#D9F4FF"),
                backgroundTop: Color(hex: "#4A5050"),
                backgroundBottom: Color(hex: "#3E4444")
            )
        case .pleasant:
            return MoodPalette(
                primary: Color(hex: "#FFE65B"),
                secondary: Color(hex: "#CDB133"),
                glow: Color(hex: "#FFF5B3"),
                backgroundTop: Color(hex: "#4C4736"),
                backgroundBottom: Color(hex: "#3B3729")
            )
        case .veryPleasant:
            return MoodPalette(
                primary: Color(hex: "#FFB347"),
                secondary: Color(hex: "#F47B3D"),
                glow: Color(hex: "#FFE1B2"),
                backgroundTop: Color(hex: "#5A452A"),
                backgroundBottom: Color(hex: "#43311E")
            )
        }
    }
}

struct MoodPalette {
    let primary: Color
    let secondary: Color
    let glow: Color
    let backgroundTop: Color
    let backgroundBottom: Color
}

struct DailyMoodEntry: Codable, Identifiable, Equatable {
    let id: String
    let patientId: String
    let dateKey: String
    let moodKey: DailyMoodKey
    let label: String
    let score: Double
    let createdAt: String?
    let updatedAt: String?

    var loggedDate: Date? {
        let rawValue = updatedAt ?? createdAt ?? ""
        return DailyMoodEntry.isoFormatter.date(from: rawValue)
            ?? DailyMoodEntry.fallbackFormatter.date(from: rawValue)
    }

    var shortLoggedTime: String {
        guard let loggedDate else { return "Logged today" }
        return DailyMoodEntry.timeFormatter.string(from: loggedDate)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

struct DailyMoodResponse: Codable {
    let success: Bool
    let data: DailyMoodEntry?
}

struct DailyMoodHistoryResponse: Codable {
    let success: Bool
    let data: [DailyMoodEntry]
    let count: Int?
}

struct DailyMoodRequest: Encodable {
    let patientId: String
    let moodKey: String
}
