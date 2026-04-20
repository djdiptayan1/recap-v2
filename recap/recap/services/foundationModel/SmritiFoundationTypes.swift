//
//  SmritiFoundationTypes.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum FoundationStreamOutcome {
    case streamed(answer: String, followup: String?)
    case guardrail(message: String)
    case refusal(message: String)
    case failed
}

enum FoundationStructuredOutcome {
    case success(SmritiResponse)
    case guardrail(message: String)
    case refusal(message: String)
    case failed
}

#if canImport(FoundationModels)
@Generable(description: "Decision on whether app tools are needed and which tools are minimally required")
struct ToolSelectionDecision {
    @Guide(description: "True only when current request requires live app data read or app-side action")
    var requiresTools: Bool

    @Guide(description: "Use getFamilyContext only when family details/contact are explicitly requested")
    var useFamilyContext: Bool

    @Guide(description: "Use getReminders for listing or checking reminders")
    var useReminderRead: Bool

    @Guide(description: "Use writeReminder for creating reminders after explicit user confirmation")
    var useReminderWrite: Bool

    @Guide(description: "Use editReminder for updating existing reminders after explicit user confirmation")
    var useReminderEdit: Bool

    @Guide(description: "Use deleteReminder for deleting reminders after explicit user confirmation")
    var useReminderDelete: Bool

    @Guide(description: "Use getQuestionPerformance when user asks about question performance")
    var useQuestionPerformance: Bool

    @Guide(description: "Use getStreakStats when user asks about streaks or progress metrics")
    var useStreakStats: Bool

    @Guide(description: "Use getJournalSummary when user asks about journal entries or summaries")
    var useJournalSummary: Bool

    @Guide(description: "Short reason for the decision")
    var reason: String?
}

enum PrimaryIntent {
    case reminderCreate
    case reminderEdit
    case reminderDelete
    case reminderRead
    case familyExplicit
    case questionPerformance
    case streakStats
    case journalSummary
    case help
    case none
}
#endif
