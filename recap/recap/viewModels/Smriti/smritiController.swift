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
                "I am here to help you navigate Alzheimer's care. You can ask me about symptoms, daily care, or upload a prescription.",
            isUser: false),
    ]
    @Published var isLoading = false
    @Published var errorMessage: String?

    // API Endpoint definition
    private enum SmritiAPI: Endpoint {
        case ask(query: String)

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
            case .ask(let query):
                return SmritiRequest(query: query)
            }
        }
    }

    func sendMessage(text: String) {
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        isLoading = true

        Task {
            do {
                let response: SmritiResponse = try await NetworkManager.shared.request(
                    endpoint: SmritiAPI.ask(query: text))

                // Format the response into a single text block for now
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
