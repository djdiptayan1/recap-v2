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
    var categoryDetails: [String: String]?
    var isCompleted: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, category, frequency, time, notes, categoryDetails, isCompleted, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(ReminderCategory.self, forKey: .category)
        frequency = try container.decode(ReminderFrequency.self, forKey: .frequency)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        categoryDetails = try container.decodeIfPresent([String: String].self, forKey: .categoryDetails)
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

    /// Returns the category-specific detail fields with their display labels
    var detailFields: [CategoryDetailField] {
        switch self {
        case .medicine:
            return [
                CategoryDetailField(key: "medicineName", label: "Medicine Name", icon: "pill.fill", placeholder: "e.g. Aspirin"),
                CategoryDetailField(key: "dosage", label: "Dosage", icon: "number", placeholder: "e.g. 500"),
                CategoryDetailField(key: "dosageUnit", label: "Dosage Unit", icon: "scalemass", placeholder: "mg", pickerOptions: ["mg", "ml", "tablets", "capsules", "drops"]),
                CategoryDetailField(key: "mealRelation", label: "Meal Relation", icon: "fork.knife", placeholder: "Select", pickerOptions: ["Before Meal", "After Meal", "With Meal", "No Preference"]),
            ]
        case .appointment:
            return [
                CategoryDetailField(key: "doctorName", label: "Doctor / Person", icon: "person.fill", placeholder: "e.g. Dr. Smith"),
                CategoryDetailField(key: "location", label: "Location", icon: "mappin.and.ellipse", placeholder: "e.g. City Hospital"),
            ]
        case .exercise:
            return [
                CategoryDetailField(key: "exerciseType", label: "Exercise Type", icon: "figure.walk", placeholder: "e.g. Walking"),
                CategoryDetailField(key: "duration", label: "Duration (minutes)", icon: "timer", placeholder: "e.g. 30"),
            ]
        case .meal:
            return [
                CategoryDetailField(key: "mealType", label: "Meal Type", icon: "fork.knife", placeholder: "Select", pickerOptions: ["Breakfast", "Lunch", "Dinner", "Snack"]),
            ]
        case .hydration:
            return [
                CategoryDetailField(key: "amount", label: "Amount", icon: "drop.fill", placeholder: "e.g. 250"),
                CategoryDetailField(key: "unit", label: "Unit", icon: "scalemass", placeholder: "Select", pickerOptions: ["ml", "oz", "cups", "glasses", "litres"]),
            ]
        case .dailyChore, .other:
            return []
        }
    }
}

/// Describes a category-specific detail field for reminder forms
struct CategoryDetailField: Identifiable {
    let key: String
    let label: String
    let icon: String
    let placeholder: String
    var pickerOptions: [String]? = nil

    var id: String { key }
}

enum ReminderFrequency: String, Codable, CaseIterable, Identifiable {
    case once = "once"
    case hourly = "hourly"
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .once: return "Once"
        case .hourly: return "Hourly"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .weekly: return "Weekly"
        case .biweekly: return "Biweekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    /// Returns suggested calendar date components and whether they should repeat,
    /// suitable for creating `UNCalendarNotificationTrigger`s.
    /// - Note: Some patterns (like biweekly) are not directly expressible as a repeating
    ///   calendar trigger and should be scheduled manually by re-queuing the next fire date
    ///   when a notification is delivered.
    func calendarDateComponents(for time: Date, calendar: Calendar = .current) -> (components: [DateComponents], repeats: Bool)? {
        switch self {
        case .once:
            let comp = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: time)
            return ([comp], false)
        case .hourly:
            // Fires every hour at the specified minute/second
            let base = calendar.dateComponents([.minute, .second], from: time)
            return ([base], true)
        case .daily:
            // Fires every day at the specified time
            let base = calendar.dateComponents([.hour, .minute, .second], from: time)
            return ([base], true)
        case .weekdays:
            // Fires Monday (2) through Friday (6) at the specified time
            let hm = calendar.dateComponents([.hour, .minute, .second], from: time)
            var list: [DateComponents] = []
            for weekday in 2...6 { // Monday=2, ..., Friday=6 in Gregorian calendar
                var c = hm
                c.weekday = weekday
                list.append(c)
            }
            return (list, true)
        case .weekends:
            // Fires on Saturday (7) and Sunday (1) at the specified time
            let hm = calendar.dateComponents([.hour, .minute, .second], from: time)
            var list: [DateComponents] = []
            for weekday in [1, 7] { // Sunday=1, Saturday=7
                var c = hm
                c.weekday = weekday
                list.append(c)
            }
            return (list, true)
        case .weekly:
            // Fires every week on the same weekday at the specified time
            let c = calendar.dateComponents([.weekday, .hour, .minute, .second], from: time)
            return ([c], true)
        case .monthly:
            // Fires every month on the same day at the specified time
            let c = calendar.dateComponents([.day, .hour, .minute, .second], from: time)
            return ([c], true)
        case .yearly:
            // Fires every year on the same month/day at the specified time
            let c = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: time)
            return ([c], true)
        case .biweekly:
            // Not directly supported by a repeating calendar trigger
            return nil
        }
    }

    /// Whether this frequency can be scheduled using a repeating `UNCalendarNotificationTrigger`.
    var supportsRepeatingCalendarTrigger: Bool {
        switch self {
            case .biweekly: return false
            case .once, .hourly, .daily, .weekdays, .weekends, .weekly, .monthly, .yearly: return true
        }
    }
}
