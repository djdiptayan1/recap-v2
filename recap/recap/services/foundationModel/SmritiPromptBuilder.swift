//
//  SmritiPromptBuilder.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
struct SmritiPromptBuilder {
    static func makePrompt(
        query: String,
        history: [SmritiHistoryMessage]?,
        context: SmritiPromptContext?,
        liveData: String? = nil,
        isHelp: Bool = false
    ) -> String {
        var sections: [String] = []

        if let contextText = context?.asInstructionContextText(), !contextText.isEmpty {
            sections.append("Context:\n\(contextText)")
        }

        if isHelp {
            sections.append("""
            System Note (CRITICAL): The user has explicitly requested help or capabilities. 
            Do NOT greet them, do NOT ask a follow up question. 
            Simply respond by listing exactly what you can do:
            1. Create and manage Reminders (Appointments, Medicine, etc.)
            2. View Daily Streaks and Question Performance
            3. Answer general questions about Alzheimer's and Dementia
            4. Display Family Contacts and relations
            """)
        }

        // Inject pre-fetched live data as source of truth
        if let liveData, !liveData.isEmpty {
            sections.append("Live app data (source of truth \u{2014} do NOT contradict or invent beyond this):\n\(liveData)")
        }

        // Limit history to 6 turns to conserve 4096-token context window
        if let history, !history.isEmpty {
            let recentHistory = history.suffix(6)
            let renderedHistory = recentHistory.map { "\($0.role): \($0.text)" }.joined(separator: "\n")
            sections.append("Recent chat:\n\(renderedHistory)")
        }

        sections.append("User message:\n\(query)")
        return sections.joined(separator: "\n\n")
    }
}
#endif
