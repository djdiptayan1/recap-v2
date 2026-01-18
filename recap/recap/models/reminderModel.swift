//
//  reminderModel.swift
//  recap
//
//  Created by Diptayan Jash on 18/01/26.
//

import Foundation
import SwiftUI

struct Reminder: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var category: ReminderCategory
    var frequency: ReminderFrequency
    var time: Date
    var notes: String?
    var isCompleted: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, category, frequency, time, notes, isCompleted, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(ReminderCategory.self, forKey: .category)
        frequency = try container.decode(ReminderFrequency.self, forKey: .frequency)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted)

        // Custom Date Decoding Helper
        func decodeDate(forKey key: CodingKeys) throws -> Date? {
            if let timestamp = try? container.decode(FirestoreTimestamp.self, forKey: key) {
                return Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
            } else if let isoString = try? container.decode(String.self, forKey: key) {
                // Try ISO8601
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: isoString) {
                    return date
                }
                // Try simpler ISO if fractional fails (e.g. standard backend JS sometimes omits)
                let simpleFormatter = ISO8601DateFormatter()
                return simpleFormatter.date(from: isoString)
            }
            // Fallback to standard double/int timestamp if needed, or null
            return nil
        }

        // Required time field
        if let decodedTime = try? decodeDate(forKey: .time) {
            time = decodedTime
        } else {
            // Fallback/Default if decoding fails (shouldn't happen if backend is consistent)
            // But 'time' is non-optional in struct.
            // Let's force try a standard decode or throw
            time = try container.decode(Date.self, forKey: .time)
        }

        createdAt = try? decodeDate(forKey: .createdAt)
        updatedAt = try? decodeDate(forKey: .updatedAt)
    }
}

enum ReminderCategory: String, Codable, CaseIterable, Identifiable {
    case medicine = "Medicine"
    case dailyChore = "Daily Chore"
    case appointment = "Appointment"
    case exercise = "Exercise"
    case meal = "Meal"
    case hydration = "Hydration"
    case other = "Other"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .medicine: return "pills.fill"
        case .dailyChore: return "house.fill"
        case .appointment: return "calendar.badge.clock"
        case .exercise: return "figure.run"
        case .meal: return "fork.knife"
        case .hydration: return "drop.fill"
        case .other: return "bell.fill"
        }
    }

    var color: Color {
        switch self {
        case .medicine: return .red
        case .dailyChore: return .blue
        case .appointment: return .purple
        case .exercise: return .green
        case .meal: return .orange
        case .hydration: return .cyan
        case .other: return .gray
        }
    }
}

enum ReminderFrequency: String, Codable, CaseIterable, Identifiable {
    case once = "once"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .once: return "Once"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
