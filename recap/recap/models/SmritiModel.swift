//
//  SmritiModel.swift
//  recap
//
//  Created by Diptayan Jash on 08/01/26.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum SmritiMode: String, Codable {
    case caregiver
    case memoryLane
}

struct FamilyMemberContext {
    let name: String
    let relation: String
}

struct SmritiPromptContext {
    var patientName: String?
    var stage: String?
    var dob: String?
    var familyMembers: [FamilyMemberContext]?
    var streakDays: Int?
    var reminders: [String]?
    var mode: SmritiMode

    func asInstructionContextText() -> String {
        var lines: [String] = []

        if let patientName, !patientName.isEmpty {
            lines.append("Patient name: \(patientName)")
        }
        if let stage, !stage.isEmpty {
            lines.append("Stage: \(stage)")
        }
        if let dob, !dob.isEmpty {
            lines.append("DOB: \(dob)")
        }

        if let familyMembers, !familyMembers.isEmpty {
            let formatted = familyMembers.map { "\($0.name) (\($0.relation))" }.joined(separator: ", ")
            lines.append("Family members: \(formatted)")
        }

        if let streakDays {
            lines.append("Current streak days: \(streakDays)")
        }

        if let reminders, !reminders.isEmpty {
            lines.append("Reminders: \(reminders.joined(separator: ", "))")
        }

        lines.append("Mode: \(mode.rawValue)")
        return lines.joined(separator: "\n")
    }

    func asBackendContext() -> SmritiContext {
        SmritiContext(
            patientName: patientName,
            stage: stage,
            dob: dob,
            familyMembers: familyMembers?.map {
                SmritiFamilyMember(name: $0.name, relation: $0.relation)
            },
            recentActivities: (streakDays != nil || reminders != nil)
                ? SmritiActivities(streakDays: streakDays, reminders: reminders)
                : nil,
            mode: mode == .memoryLane ? "memoryLane" : nil
        )
    }
}

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

#if canImport(FoundationModels)
@Generable(description: "Smriti structured response")
struct SmritiGeneratedResponse {
    @Guide(description: "Main assistant answer in calm, empathetic language")
    var answer: String

    @Guide(description: "Warm personalized follow-up question that encourages memory recall")
    var followupPrompt: String

    @Guide(description: "Actionable care tips, only when relevant", .count(0...6))
    var careStrategies: [String]?

    @Guide(description: "Short consult-a-professional reminder only for medical-care questions")
    var medicalDisclaimer: String?

    @Guide(description: "Optional empathetic support note for emotional situations")
    var supportiveNote: String?

    @Guide(description: "Optional evidence links when specific factual claims are made", .count(0...2))
    var sources: [SmritiSource]?
}

@Generable(description: "Reference source")
struct SmritiSource: Codable, Hashable {
    @Guide(description: "Human-readable source name")
    var name: String

    @Guide(description: "HTTPS URL")
    var url: String
}
#else
struct SmritiSource: Codable, Hashable {
    let name: String
    let url: String
}
#endif

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

#if canImport(FoundationModels)
extension SmritiResponse {
    init(generated payload: SmritiGeneratedResponse) {
        self.summary = nil
        self.answer = payload.answer
        self.care_strategies = payload.careStrategies
        self.medical_disclaimer = payload.medicalDisclaimer
        self.sources = payload.sources
        self.supportive_note = payload.supportiveNote
        self.followup_prompt = payload.followupPrompt
    }
}
#endif

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
