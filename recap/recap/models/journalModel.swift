// journalModel.swift
// recap
// Created by Copilot on 25/02/26.

import Foundation

struct JournalEntry: Identifiable, Codable, Equatable {
    let id: String
    let patientId: String?
    let title: String?
    let content: String?
    let mood: String?
    let audioURL: String?
    let audioDuration: Double?
    let createdBy: String?
    let createdAt: String?
    let updatedAt: String?

    var moodEmoji: String {
        switch mood?.lowercased() {
        case "happy": return "😊"
        case "sad": return "😢"
        case "neutral": return "😐"
        case "anxious": return "😰"
        case "calm": return "😌"
        case "grateful": return "🙏"
        default: return "📝"
        }
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let dateObj = formatter.date(from: createdAt ?? "") {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "d MMM yyyy 'at' h:mm a"
            return displayFormatter.string(from: dateObj)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let dateObj = formatter.date(from: createdAt ?? "") {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "d MMM yyyy 'at' h:mm a"
            return displayFormatter.string(from: dateObj)
        }
        return createdAt ?? "Unknown date"
    }

    var hasAudio: Bool {
        audioURL != nil && !(audioURL?.isEmpty ?? true)
    }

    var hasText: Bool {
        content != nil && !(content?.isEmpty ?? true)
    }
}

struct JournalResponse: Codable {
    let success: Bool
    let data: [JournalEntry]
    let count: Int?
}

struct JournalSingleResponse: Codable {
    let success: Bool
    let data: JournalEntry
}

struct JournalCreateRequest: Encodable {
    let patientId: String
    let title: String?
    let content: String?
    let mood: String?
    let audioBase64: String?
    let audioDuration: Double?
    let createdBy: String
}

struct JournalUpdateRequest: Encodable {
    let patientId: String
    let title: String?
    let content: String?
    let mood: String?
}
