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
    @Published var foundationPrompt: FoundationAvailabilityPrompt?

    private var promptContext: SmritiPromptContext?
    private var userIdentifier: String = ""
    private var selectedProvider: AIProviderKind = .gemini

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
            promptContext = nil
            setupGreeting(name: nil, memoryLane: isMemoryLane)
            return
        }

        let familyContext = familyMembers?.map {
            FamilyMemberContext(name: $0.name, relation: $0.relation)
        }

        promptContext = SmritiPromptContext(
            patientName: patient.firstName,
            stage: patient.stage.isEmpty ? nil : patient.stage,
            dob: patient.dateOfBirth.isEmpty ? nil : patient.dateOfBirth,
            familyMembers: familyContext,
            streakDays: streakDays,
            reminders: reminderTitles,
            mode: isMemoryLane ? .memoryLane : .caregiver
        )

        setupGreeting(name: patient.firstName, memoryLane: isMemoryLane)
    }

    func initializeProviderAndUsage() async {
        await refreshProviderState()
        await fetchUsage()
    }

    func setMemoryLaneMode(_ enabled: Bool) {
        guard var ctx = promptContext else {
            promptContext = SmritiPromptContext(
                patientName: nil,
                stage: nil,
                dob: nil,
                familyMembers: nil,
                streakDays: nil,
                reminders: nil,
                mode: enabled ? .memoryLane : .caregiver
            )
            setupGreeting(name: nil, memoryLane: enabled)
            return
        }
        ctx.mode = enabled ? .memoryLane : .caregiver
        promptContext = ctx
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
        guard selectedProvider == .gemini else {
            usageInfo = nil
            isRateLimited = false
            rateLimitMessage = nil
            return
        }

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
        guard !(selectedProvider == .gemini && isRateLimited) else {
            let limitMsg = ChatMessage(
                text: rateLimitMessage
                    ?? "You've reached your message limit. Please try again later. 💛",
                isUser: false
            )
            messages.append(limitMsg)
            return
        }

        guard !isLoading else {
            return
        }

        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        isLoading = true
        followupPrompt = nil

        let history = buildHistory()

        Task {
            let provider = await resolveProviderForCurrentTurn()

            switch provider {
            case .foundation:
                let onDeviceSuccess = await sendFoundationMessage(query: text, history: history)
                if !onDeviceSuccess {
                    messages.append(
                        ChatMessage(
                            text:
                                "Apple Intelligence is temporarily unavailable right now. Please tap Retry and try again.",
                            isUser: false
                        )
                    )
                }
            case .gemini:
                _ = await sendGeminiFlow(query: text, history: history)
            }

            self.isLoading = false

            if self.selectedProvider == .gemini {
                await fetchUsage()
            }
        }
    }

    private func sendGeminiFlow(query: String, history: [SmritiHistoryMessage]?) async -> Bool {
        let streamSuccess = await sendStreaming(query: query, history: history)
        if !streamSuccess {
            await sendStructured(query: query, history: history)
        }
        return true
    }

    private func refreshProviderState() async {
        _ = await resolveProviderForCurrentTurn()
        SmritiFoundationPrewarmService.shared.prewarmIfPossible()
    }

    func retryProviderAvailability() async {
        await refreshProviderState()
        await fetchUsage()
    }

    private func sendFoundationMessage(query: String, history: [SmritiHistoryMessage]?) async -> Bool {
        let placeholder = ChatMessage(text: "", isUser: false)
        let placeholderID = placeholder.id
        messages.append(placeholder)

        let outcome = await SmritiFoundationEngine.shared.streamStructuredResponse(
            query: query,
            history: history,
            context: promptContext,
            fallbackPatientId: userIdentifier,
            onPartial: { [weak self] answer, followup in
                guard let self else { return }
                if let answer, let idx = self.messages.firstIndex(where: { $0.id == placeholderID }) {
                    self.messages[idx].text = self.sanitizeAssistantText(answer)
                }
                if let followup, !followup.isEmpty {
                    self.followupPrompt = followup
                }
            }
        )

        switch outcome {
        case .streamed(let answer, let followup):
            if answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                removePlaceholder(id: placeholderID)
                return await sendFoundationNonStreaming(query: query, history: history)
            }

            if let followup, !followup.isEmpty {
                followupPrompt = followup
            }
            return true

        case .guardrail(let message), .refusal(let message):
            replacePlaceholder(
                id: placeholderID,
                with: message
            )
            return true

        case .failed:
            removePlaceholder(id: placeholderID)
            return await sendFoundationNonStreaming(query: query, history: history)
        }
    }

    private func sendFoundationNonStreaming(query: String, history: [SmritiHistoryMessage]?) async -> Bool {
        let outcome = await SmritiFoundationEngine.shared.generateStructuredResponse(
            query: query,
            history: history,
            context: promptContext,
            fallbackPatientId: userIdentifier
        )

        switch outcome {
        case .success(let adapted):
            appendStructuredResponseToUI(adapted)
            return true

        case .guardrail(let message), .refusal(let message):
            messages.append(
                ChatMessage(
                    text: message,
                    isUser: false
                )
            )
            return true

        case .failed:
            return false
        }
    }

    private func resolveProviderForCurrentTurn() async -> AIProviderKind {
        let decision = await FoundationAvailabilityService.shared.resolveProvider()
        foundationPrompt = decision.prompt
        selectedProvider = decision.provider
        if decision.provider != .gemini {
            clearUsageState()
        }
        return decision.provider
    }

    private func clearUsageState() {
        usageInfo = nil
        isRateLimited = false
        rateLimitMessage = nil
    }

    // MARK: - Streaming (fast, plain text)
    private func sendStreaming(query: String, history: [SmritiHistoryMessage]?) async -> Bool {
        // Add placeholder — track by ID not index
        let placeholder = ChatMessage(text: "", isUser: false)
        let placeholderID = placeholder.id
        messages.append(placeholder)

        let stream = NetworkManager.shared.streamRequest(
            endpoint: SmritiAPI.stream(
                query: query, context: promptContext?.asBackendContext(), history: history,
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

            if let idx = messages.firstIndex(where: { $0.id == placeholderID }) {
                messages[idx].text = sanitizeAssistantText(fullText)
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

    private func replacePlaceholder(id: UUID, with text: String) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx].text = text
        } else {
            messages.append(ChatMessage(text: text, isUser: false))
        }
    }

    // MARK: - Structured (fallback, full JSON)
    private func sendStructured(query: String, history: [SmritiHistoryMessage]?) async {
        do {
            let response: SmritiResponse = try await NetworkManager.shared.request(
                endpoint: SmritiAPI.ask(
                    query: query, context: promptContext?.asBackendContext(), history: history,
                    userIdentifier: userIdentifier))

            appendStructuredResponseToUI(response)

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

    private func appendStructuredResponseToUI(_ response: SmritiResponse) {
        var responseText = sanitizeAssistantText(response.answer)

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

    private func sanitizeAssistantText(_ text: String) -> String {
        let pattern = "^(?:(?:hello|hi|namaste)\\s+[A-Za-z]+[!,.:\\-]?\\s*)+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(location: 0, length: text.utf16.count)
        let sanitized = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
