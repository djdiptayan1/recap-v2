// journalModel.swift
// recap
// Created by Copilot on 25/02/26.

import Foundation

// Firestore Timestamp object shape emitted by the Firebase JS client SDK.
// The backend now converts these to ISO strings, but this struct lets the iOS
// model decode entries that were stored before that fix was deployed.
private struct _FirestoreTimestamp: Decodable {
    let seconds: Int
    let nanoseconds: Int?

    var isoString: String {
        let date = Date(timeIntervalSince1970: Double(seconds))
        return ISO8601DateFormatter().string(from: date)
    }
}

// MARK: - Photo

/// A single photo attached to a journal/memory entry.
struct JournalPhoto: Codable, Equatable {
    let url: String
    let publicId: String?
    let caption: String?
    let thumbnailURL: String?
    let detailURL: String?
    let originalURL: String?
}

extension JournalPhoto: Identifiable {
    var id: String { url }
}

/// Payload for uploading a new photo with a journal entry.
struct JournalPhotoUpload: Encodable {
    let imageBase64: String
    let caption: String?
}

// MARK: - Entry

struct JournalEntry: Identifiable, Codable, Equatable {
    let id: String
    let patientId: String?
    let title: String?
    let content: String?
    let mood: String?
    let audioURL: String?
    let audioDuration: Double?
    let createdBy: String?
    // Memory-book fields
    let entryType: String?      // 'journal' | 'memory'
    let people: String?         // comma-separated names
    let place: String?          // location label
    let eventTag: String?       // birthday, holiday, family, daily, …
    let photos: [JournalPhoto]?
    // Stored as a plain ISO string after the backend fix, but we keep a
    // custom decoder so older entries (Firestore Timestamp objects) still decode.
    let createdAt: String?
    let updatedAt: String?

    // MARK: - Custom decoder for flexible Timestamp/String dates

    enum CodingKeys: String, CodingKey {
        case id, patientId, title, content, mood, audioURL, audioDuration
        case createdBy, createdAt, updatedAt
        case entryType, people, place, eventTag, photos
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(String.self, forKey: .id)
        patientId     = try c.decodeIfPresent(String.self, forKey: .patientId)
        title         = try c.decodeIfPresent(String.self, forKey: .title)
        content       = try c.decodeIfPresent(String.self, forKey: .content)
        mood          = try c.decodeIfPresent(String.self, forKey: .mood)
        audioURL      = try c.decodeIfPresent(String.self, forKey: .audioURL)
        audioDuration = try c.decodeIfPresent(Double.self,  forKey: .audioDuration)
        createdBy     = try c.decodeIfPresent(String.self, forKey: .createdBy)
        entryType     = try c.decodeIfPresent(String.self, forKey: .entryType)
        people        = try c.decodeIfPresent(String.self, forKey: .people)
        place         = try c.decodeIfPresent(String.self, forKey: .place)
        eventTag      = try c.decodeIfPresent(String.self, forKey: .eventTag)
        photos        = try c.decodeIfPresent([JournalPhoto].self, forKey: .photos)
        createdAt     = Self.decodeFlexibleDate(c, key: .createdAt)
        updatedAt     = Self.decodeFlexibleDate(c, key: .updatedAt)
    }

    /// Try to decode the field as a String; fall back to a Firestore Timestamp object.
    private static func decodeFlexibleDate(
        _ c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> String? {
        if let str = try? c.decodeIfPresent(String.self, forKey: key) {
            return str
        }
        if let ts = try? c.decodeIfPresent(_FirestoreTimestamp.self, forKey: key) {
            return ts.isoString
        }
        return nil
    }

    // MARK: - Computed properties

    var isMemory: Bool { entryType == "memory" || hasPhotos }

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

    var hasPhotos: Bool {
        !(photos?.isEmpty ?? true)
    }
}

// MARK: - Responses / Requests

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
    let entryType: String?
    let people: String?
    let place: String?
    let eventTag: String?
    let photoBase64s: [JournalPhotoUpload]?
}

struct JournalUpdateRequest: Encodable {
    let patientId: String
    let title: String?
    let content: String?
    let mood: String?
}
