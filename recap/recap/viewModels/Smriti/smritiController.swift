//
//  smritiController.swift
//  recap
//
//  Created by Diptayan Jash on 08/01/26.
//

import Combine
import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    var text: String
    let isUser: Bool
}

@MainActor
class SmritiViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var followupPrompt: String?
    @Published var usageInfo: SmritiUsageResponse?
    @Published var isRateLimited = false
    @Published var rateLimitMessage: String?

    private var patientContext: SmritiContext?
    private var userIdentifier: String = ""

    // API Endpoints
    private enum SmritiAPI: Endpoint {
        case ask(
            query: String, context: SmritiContext?, history: [SmritiHistoryMessage]?,
            userIdentifier: String)
        case stream(
            query: String, context: SmritiContext?, history: [SmritiHistoryMessage]?,
            userIdentifier: String)
        case usage(userIdentifier: String)

        var path: String {
            switch self {
            case .ask:
                return AppConfig.ApiEndpoints.smriti
            case .stream:
                return AppConfig.ApiEndpoints.smriti + "/stream"
            case .usage(let userIdentifier):
                return AppConfig.ApiEndpoints.smriti + "/usage/\(userIdentifier)"
            }
        }

        var method: HTTPMethod {
            switch self {
            case .ask, .stream:
                return .post
            case .usage:
                return .get
            }
        }

        var body: Encodable? {
            switch self {
            case .ask(let query, let context, let history, let userIdentifier),
                .stream(let query, let context, let history, let userIdentifier):
                return SmritiRequest(
                    query: query, context: context, history: history, userIdentifier: userIdentifier
                )
            case .usage:
                return nil
            }
        }
    }

    func configure(
        patient: patientModel?, familyMembers: [FamilyMember]?, streakDays: Int? = nil,
        reminderTitles: [String]? = nil, isMemoryLane: Bool = false,
        userIdentifier: String = ""
    ) {
        self.userIdentifier = userIdentifier

        guard let patient = patient else {
            patientContext = nil
            setupGreeting(name: nil, memoryLane: isMemoryLane)
            return
        }

        let familyContext = familyMembers?.map {
            SmritiFamilyMember(name: $0.name, relation: $0.relation)
        }

        let activities = SmritiActivities(
            streakDays: streakDays,
            reminders: reminderTitles
        )

        patientContext = SmritiContext(
            patientName: patient.firstName,
            stage: patient.stage.isEmpty ? nil : patient.stage,
            dob: patient.dateOfBirth.isEmpty ? nil : patient.dateOfBirth,
            familyMembers: familyContext,
            recentActivities: (streakDays != nil || reminderTitles != nil) ? activities : nil,
            mode: isMemoryLane ? "memoryLane" : nil
        )

        setupGreeting(name: patient.firstName, memoryLane: isMemoryLane)
    }

    func setMemoryLaneMode(_ enabled: Bool) {
        guard let ctx = patientContext else {
            patientContext = SmritiContext(
                patientName: nil, stage: nil, dob: nil,
                familyMembers: nil, recentActivities: nil,
                mode: enabled ? "memoryLane" : nil
            )
            setupGreeting(name: nil, memoryLane: enabled)
            return
        }
        patientContext = SmritiContext(
            patientName: ctx.patientName,
            stage: ctx.stage,
            dob: ctx.dob,
            familyMembers: ctx.familyMembers,
            recentActivities: ctx.recentActivities,
            mode: enabled ? "memoryLane" : nil
        )
        setupGreeting(name: ctx.patientName, memoryLane: enabled)
    }

    private func setupGreeting(name: String?, memoryLane: Bool = false) {
        let greeting =
            name != nil
            ? "Namaste, \(name!)! I am Smriti."
            : "Namaste! I am Smriti."
        let subtitle =
            memoryLane
            ? "Let's take a walk down memory lane together. Share your favorite memories, and I'll be right here to listen. 💛"
            : "I am here to help you navigate Alzheimer's care. You can ask me about symptoms, daily care, or share your memories with me. 💛"
        messages = [
            ChatMessage(text: greeting, isUser: false),
            ChatMessage(text: subtitle, isUser: false),
        ]
        followupPrompt = nil
    }

    private func buildHistory() -> [SmritiHistoryMessage]? {
        let chatMessages = Array(messages.dropFirst(2))
        guard !chatMessages.isEmpty else { return nil }
        let recent = chatMessages.suffix(20)
        return recent.map {
            SmritiHistoryMessage(
                role: $0.isUser ? "user" : "model",
                text: $0.text
            )
        }
    }

    // MARK: - Usage Fetching

    func fetchUsage() async {
        guard !userIdentifier.isEmpty else { return }

        do {
            let response: SmritiUsageResponse = try await NetworkManager.shared.request(
                endpoint: SmritiAPI.usage(userIdentifier: userIdentifier))

            self.usageInfo = response
            self.isRateLimited = response.dailyRemaining <= 0 || response.weeklyRemaining <= 0

            if self.isRateLimited {
                if response.dailyRemaining <= 0 {
                    self.rateLimitMessage =
                        "You've used all \(response.dailyLimit) messages for today. Come back tomorrow! 💛"
                } else {
                    self.rateLimitMessage =
                        "You've used all \(response.weeklyLimit) messages this week. Your quota resets on Monday! 💛"
                }
            } else {
                self.rateLimitMessage = nil
            }
        } catch {
            // Silently fail — don't block the user from trying
            print("Failed to fetch Smriti usage: \(error.localizedDescription)")
        }
    }

    // MARK: - Send Message

    func sendMessage(text: String) {
        guard !isRateLimited else {
            let limitMsg = ChatMessage(
                text: rateLimitMessage
                    ?? "You've reached your message limit. Please try again later. 💛",
                isUser: false
            )
            messages.append(limitMsg)
            return
        }

        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        isLoading = true
        followupPrompt = nil

        let history = buildHistory()

        Task {
            let streamSuccess = await sendStreaming(query: text, history: history)
            if !streamSuccess {
                await sendStructured(query: text, history: history)
            }
            self.isLoading = false

            // Refresh usage after sending a message
            await fetchUsage()
        }
    }

    // MARK: - Streaming (fast, plain text)
    private func sendStreaming(query: String, history: [SmritiHistoryMessage]?) async -> Bool {
        // Add placeholder — track by ID not index
        let placeholder = ChatMessage(text: "", isUser: false)
        let placeholderID = placeholder.id
        messages.append(placeholder)

        let stream = NetworkManager.shared.streamRequest(
            endpoint: SmritiAPI.stream(
                query: query, context: patientContext, history: history,
                userIdentifier: userIdentifier),
            timeoutSeconds: 15
        )

        var fullText = ""
        do {
            for try await chunk in stream {
                fullText += chunk
                // Find message by ID to safely update
                if let idx = messages.firstIndex(where: { $0.id == placeholderID }) {
                    messages[idx].text = fullText
                }
            }

            // If we got no text, remove placeholder and fail
            if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                removePlaceholder(id: placeholderID)
                return false
            }

            extractFollowup(from: fullText)
            return true
        } catch {
            // Check if this is a 429 rate limit error
            if case NetworkError.httpError(let statusCode) = error, statusCode == 429 {
                removePlaceholder(id: placeholderID)
                handleRateLimitHit()
                return true  // Return true to prevent structured fallback
            }
            // Always remove placeholder on error
            removePlaceholder(id: placeholderID)
            return false
        }
    }

    /// Safely remove a placeholder message by its ID
    private func removePlaceholder(id: UUID) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages.remove(at: idx)
        }
    }

    // MARK: - Structured (fallback, full JSON)
    private func sendStructured(query: String, history: [SmritiHistoryMessage]?) async {
        do {
            let response: SmritiResponse = try await NetworkManager.shared.request(
                endpoint: SmritiAPI.ask(
                    query: query, context: patientContext, history: history,
                    userIdentifier: userIdentifier))

            var responseText = response.answer

            if let strategies = response.care_strategies, !strategies.isEmpty {
                responseText +=
                    "\n\n**Care Strategies:**\n"
                    + strategies.map { "• \($0)" }.joined(separator: "\n")
            }

            if let sources = response.sources, !sources.isEmpty {
                responseText +=
                    "\n\n**Sources:**\n"
                    + sources.map { "• [\($0.name)](\($0.url))" }.joined(separator: "\n")
            }

            if let note = response.supportive_note, !note.isEmpty {
                responseText += "\n\n*\(note)*"
            }

            if let disclaimer = response.medical_disclaimer, !disclaimer.isEmpty {
                responseText += "\n\n_\(disclaimer)_"
            }

            if let followup = response.followup_prompt, !followup.isEmpty {
                responseText += "\n\n💭 **\(followup)**"
            }

            let aiMessage = ChatMessage(text: responseText, isUser: false)
            self.messages.append(aiMessage)

            if let followup = response.followup_prompt, !followup.isEmpty {
                self.followupPrompt = followup
            }

        } catch {
            // Check if this is a 429 rate limit error
            if case NetworkError.httpError(let statusCode) = error, statusCode == 429 {
                handleRateLimitHit()
                return
            }

            self.errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(
                text:
                    "I apologize, but I'm having trouble connecting right now. Please try again in a moment. 🙏",
                isUser: false)
            self.messages.append(errorMsg)
        }
    }

    /// Handle a 429 rate limit response
    private func handleRateLimitHit() {
        isRateLimited = true
        rateLimitMessage =
            rateLimitMessage ?? "You've reached your message limit. Please try again later. 💛"

        let limitMsg = ChatMessage(
            text: rateLimitMessage!,
            isUser: false
        )
        messages.append(limitMsg)

        // Refresh usage info
        Task {
            await fetchUsage()
        }
    }

    private func extractFollowup(from text: String) {
        let lines = text.components(separatedBy: "\n")
        if let lastMeaningful = lines.last(where: {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty
        }),
            lastMeaningful.contains("💭")
        {
            let prompt =
                lastMeaningful
                .replacingOccurrences(of: "💭", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !prompt.isEmpty {
                self.followupPrompt = prompt
            }
        }
    }
}
