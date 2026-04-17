//
//  ToolShared.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

enum SmritiToolError: Error {
    case missingIdentity
    case networkFailure
}

enum FoundationToolAPI: Endpoint {
    case familyMembers(documentID: String)
    case reminders(patientId: String)
    case addReminder(body: Data)
    case editReminder(body: Data)
    case deleteReminder(body: ToolDeleteReminderRequest)
    case dailyQuestions(patientId: String)
    case streakStats(documentID: String)
    case journal(patientId: String, limit: Int)

    var path: String {
        switch self {
        case .familyMembers(let documentID):
            return AppConfig.ApiEndpoints.familyMembers + "/\(documentID)"
        case .reminders:
            return AppConfig.ApiEndpoints.reminders
        case .addReminder:
            return AppConfig.ApiEndpoints.reminders
        case .editReminder:
            return AppConfig.ApiEndpoints.reminders
        case .deleteReminder:
            return AppConfig.ApiEndpoints.reminders
        case .dailyQuestions:
            return AppConfig.ApiEndpoints.getDailyQuestions
        case .streakStats(let documentID):
            return AppConfig.ApiEndpoints.streakStats + "/\(documentID)"
        case .journal:
            return AppConfig.ApiEndpoints.journal
        }
    }

    var method: HTTPMethod {
        switch self {
        case .addReminder:
            return .post
        case .editReminder:
            return .put
        case .deleteReminder:
            return .delete
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .familyMembers, .streakStats, .addReminder, .editReminder, .deleteReminder:
            return nil
        case .reminders(let patientId), .dailyQuestions(let patientId):
            return [URLQueryItem(name: "patientId", value: patientId)]
        case .journal(let patientId, let limit):
            return [
                URLQueryItem(name: "patientId", value: patientId),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        }
    }

    var body: Encodable? {
        switch self {
        case .addReminder(let body):
            return body
        case .editReminder(let body):
            return body
        case .deleteReminder(let body):
            return body
        default:
            return nil
        }
    }
}

struct ToolAddReminderRequest: Codable {
    let patientId: String
    let title: String
    let category: String
    let frequency: String
    let time: Date
    let notes: String?
    let categoryDetails: [String: String]?
}

struct ToolEditReminderRequest: Codable {
    let patientId: String
    let reminderId: String
    let title: String?
    let category: String?
    let frequency: String?
    let time: Date?
    let notes: String?
    let categoryDetails: [String: String]?
}

struct ToolDeleteReminderRequest: Codable {
    let patientId: String
    let reminderId: String
}

enum ReminderDetailsValidator {
    static func requiredKeys(for category: ReminderCategory) -> [String] {
        switch category {
        case .medicine:
            return ["medicineName", "dosage", "dosageUnit", "mealRelation"]
        case .appointment:
            return ["doctorName", "location"]
        case .exercise:
            return ["exerciseType", "duration"]
        case .meal:
            return ["mealType"]
        case .hydration:
            return ["amount", "unit"]
        case .dailyChore, .other:
            return []
        }
    }

    static func missingKeys(for category: ReminderCategory, details: [String: String]) -> [String] {
        requiredKeys(for: category).filter { key in
            let value = details[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty
        }
    }
}
#endif
