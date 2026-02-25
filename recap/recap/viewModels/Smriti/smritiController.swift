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
    let text: String
    let isUser: Bool
}

@MainActor
class SmritiViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(text: "Namaste! I am Smriti.", isUser: false),
        ChatMessage(
            text:
                "I am here to help you navigate Alzheimer's care. You can ask me about symptoms, daily care, or share your memories with me.",
            isUser: false),
    ]
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var patientContext: SmritiContext?

    // API Endpoint definition
    private enum SmritiAPI: Endpoint {
        case ask(query: String, context: SmritiContext?, history: [SmritiHistoryMessage]?)

        var path: String {
            switch self {
            case .ask:
                return AppConfig.ApiEndpoints.smriti
            }
        }

        var method: HTTPMethod {
            switch self {
            case .ask:
                return .post
            }
        }

        var body: Encodable? {
            switch self {
            case .ask(let query, let context, let history):
                return SmritiRequest(query: query, context: context, history: history)
            }
        }
    }

    func configure(patient: patientModel?, familyMembers: [FamilyMember]?) {
        guard let patient = patient else {
            patientContext = nil
            setupGreeting(name: nil)
            return
        }

        let familyContext = familyMembers?.map {
            SmritiFamilyMember(name: $0.name, relation: $0.relation)
        }

        patientContext = SmritiContext(
            patientName: patient.firstName,
            stage: patient.stage.isEmpty ? nil : patient.stage,
            familyMembers: familyContext
        )

        setupGreeting(name: patient.firstName)
    }

    private func setupGreeting(name: String?) {
        let greeting = name != nil
            ? "Namaste, \(name!)! I am Smriti."
            : "Namaste! I am Smriti."
        messages = [
            ChatMessage(text: greeting, isUser: false),
            ChatMessage(
                text:
                    "I am here to help you navigate Alzheimer's care. You can ask me about symptoms, daily care, or share your memories with me.",
                isUser: false),
        ]
    }

    private func buildHistory() -> [SmritiHistoryMessage]? {
        // Skip greeting messages (first 2), cap at last 6 messages
        let chatMessages = Array(messages.dropFirst(2))
        guard !chatMessages.isEmpty else { return nil }
        let recent = chatMessages.suffix(6)
        return recent.map {
            SmritiHistoryMessage(
                role: $0.isUser ? "user" : "model",
                text: $0.text
            )
        }
    }

    func sendMessage(text: String) {
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        isLoading = true

        let history = buildHistory()

        Task {
            do {
                let response: SmritiResponse = try await NetworkManager.shared.request(
                    endpoint: SmritiAPI.ask(
                        query: text,
                        context: patientContext,
                        history: history
                    ))

                // Format the response into a single text block
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

                if let note = response.supportive_note {
                    responseText += "\n\n*\(note)*"
                }

                if let disclaimer = response.medical_disclaimer {
                    responseText += "\n\n_\(disclaimer)_"
                }

                if let followup = response.followup_prompt, !followup.isEmpty {
                    responseText += "\n\n💭 **\(followup)**"
                }

                let aiMessage = ChatMessage(text: responseText, isUser: false)
                self.messages.append(aiMessage)

            } catch {
                self.errorMessage = error.localizedDescription
                let errorMsg = ChatMessage(
                    text:
                        "I apologize, but I'm having trouble connecting right now. Please try again.",
                    isUser: false)
                self.messages.append(errorMsg)
            }
            self.isLoading = false
        }
    }
}
