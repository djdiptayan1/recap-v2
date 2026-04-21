//
//  SmritiIntentResolver.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
struct SmritiIntentResolver {
    
    static func resolveToolPlan(for userQuery: String, history: [SmritiHistoryMessage]? = nil) -> ToolSelectionDecision {
        // Evaluate base query
        let queryIntent = detectPrimaryIntent(in: userQuery)
        
        // If query intent is strictly generic, but we are in the middle of a reminder creation flow, inherit the flow!
        let intent = inheritIntentFromHistoryIfNecessary(queryIntent: queryIntent, history: history)
        
        let plan = fallbackToolPlan(for: userQuery, overridingIntent: intent)
        return normalizedToolPlan(plan, determinedIntent: intent)
    }

    private static func inheritIntentFromHistoryIfNecessary(queryIntent: PrimaryIntent, history: [SmritiHistoryMessage]?) -> PrimaryIntent {
        guard queryIntent == .none || queryIntent == .reminderCreate else {
            return queryIntent
        }
        
        // If we didn't firmly identify a robust intent OR we guessed reminderCreate, let's check history
        guard let history = history, !history.isEmpty else {
            return queryIntent
        }
        
        // Look at the last message from Smriti (model)
        for msg in history.reversed() {
            if msg.role == "model" || msg.role == "Smriti" {
                let lowerText = msg.text.lowercased()
                if lowerText.contains("missing required details") || lowerText.contains("missing required fields") || (lowerText.contains("reminder not created") && lowerText.contains("ask the user")) {
                    // Smriti was asking for missing fields for a reminder!
                    return .reminderCreate
                }
                break // Only care about the immediate last model message
            }
        }
        
        return queryIntent
    }

    private static func detectPrimaryIntent(in userQuery: String) -> PrimaryIntent {
        let q = userQuery.lowercased()

        let helpPhrases = ["/help", "what can you do", "capabilities", "how can you help", "what are your features"]
        if helpPhrases.contains(where: { q.contains($0) }) {
            return .help
        }

        // Broaden reminder detection and properly separate read vs. write intents
        let asksReminder = q.contains("remind") || q.contains("reminder") || q.contains("medication") || q.contains("medicine") || q.contains("pill") || q.contains("dose") || q.contains("tablet") || q.contains("appointment") || q.contains("doctor")

        if asksReminder {
            let isDelete = q.contains("delete") || q.contains("remove") || q.contains("cancel")
            if isDelete {
                return .reminderDelete
            }

            let isEdit = q.contains("edit") || q.contains("update") || q.contains("change") || q.contains("reschedule")
            if isEdit {
                return .reminderEdit
            }

            // Read triggers include natural phrasing and time windows
            let readPhrases = [
                "list", "show", "what", "upcoming", "check", "any", "today", "tonight", "tomorrow",
                "due", "pending", "schedule", "scheduled", "do i have", "do we have", "are there",
                "what's on", "what’s on", "what is on", "what do i have"
            ]
            let mentionsRead = readPhrases.contains { phrase in q.contains(phrase) }
            if mentionsRead {
                return .reminderRead
            }

            // Default to create only when no read/edit/delete signals are present
            return .reminderCreate
        }

        // Journal / memories synonyms
        let journalKeywords = [
            "journal", "journaling", "diary", "entry", "entries", "note", "notes",
            "memory book", "memory lane", "memories", "photos", "pictures", "gallery", "scrapbook"
        ]
        if journalKeywords.contains(where: { q.contains($0) }) {
            return .journalSummary
        }

        if q.contains("family") || q.contains("relation") || q.contains("contact") {
            return .familyExplicit
        }

        if q.contains("streak") {
            return .streakStats
        }

        if q.contains("question") && (q.contains("daily") || q.contains("performance") || q.contains("score")) {
            return .questionPerformance
        }

        return .none
    }

    private static func fallbackToolPlan(for userQuery: String, overridingIntent: PrimaryIntent) -> ToolSelectionDecision {
        let q = userQuery.lowercased()

        let asksFamily = q.contains("family") || q.contains("relation") || q.contains("contact")

        // Expanded reminder detection and read logic
        let asksReminder = overridingIntent == .reminderCreate || q.contains("remind") || q.contains("reminder") || q.contains("medication") || q.contains("medicine") || q.contains("pill") || q.contains("dose") || q.contains("tablet") || q.contains("appointment") || q.contains("doctor")
        let isDeleteReminder = asksReminder && (q.contains("delete") || q.contains("remove") || q.contains("cancel"))
        let isEditReminder = asksReminder && (q.contains("edit") || q.contains("update") || q.contains("change") || q.contains("reschedule"))
        let readPhrases = [
            "list", "show", "what", "upcoming", "check", "any", "today", "tonight", "tomorrow",
            "due", "pending", "schedule", "scheduled", "do i have", "do we have", "are there",
            "what's on", "what’s on", "what is on", "what do i have"
        ]
        let isReadReminder = asksReminder && readPhrases.contains { phrase in q.contains(phrase) }
        let isWriteReminder = overridingIntent == .reminderCreate || (asksReminder && !isDeleteReminder && !isEditReminder && !isReadReminder)

        // Expanded journal detection
        let journalKeywords = [
            "journal", "journaling", "diary", "entry", "entries", "note", "notes",
            "memory book", "memory lane", "memories", "photos", "pictures", "gallery", "scrapbook"
        ]
        let useJournal = journalKeywords.contains { kw in q.contains(kw) }

        let useStreak = q.contains("streak")
        let useQuestion = q.contains("question") && (q.contains("daily") || q.contains("performance") || q.contains("score"))
        

        var requiresTools = asksFamily || asksReminder || useJournal || useStreak || useQuestion
        
        if overridingIntent == .help || overridingIntent == .none {
            requiresTools = false
        }

        return ToolSelectionDecision(
            requiresTools: requiresTools,
            useFamilyContext: asksFamily && !asksReminder,
            useReminderRead: isReadReminder,
            useReminderWrite: isWriteReminder,
            useReminderEdit: isEditReminder,
            useReminderDelete: isDeleteReminder,
            useQuestionPerformance: useQuestion,
            useStreakStats: useStreak,
            useJournalSummary: useJournal,
            reason: "fallback-plan"
        )
    }

    private static func normalizedToolPlan(_ plan: ToolSelectionDecision, determinedIntent: PrimaryIntent) -> ToolSelectionDecision {
        var normalized = plan

        switch determinedIntent {
        case .help:
            normalized = ToolSelectionDecision(
                requiresTools: false,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-help"
            )
        case .reminderCreate:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: true,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-reminder-create"
            )
        case .reminderEdit:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: true,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-reminder-edit"
            )
        case .reminderDelete:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: true,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-reminder-delete"
            )
        case .reminderRead:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: true,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-reminder-read"
            )
        case .familyExplicit:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: true,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-family"
            )
        case .questionPerformance:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: true,
                useStreakStats: false,
                useJournalSummary: false,
                reason: "intent-question-performance"
            )
        case .streakStats:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: true,
                useJournalSummary: false,
                reason: "intent-streak"
            )
        case .journalSummary:
            normalized = ToolSelectionDecision(
                requiresTools: true,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: true,
                reason: "intent-journal"
            )
        case .none:
            break
        }

        if !normalized.requiresTools {
            return ToolSelectionDecision(
                requiresTools: false,
                useFamilyContext: false,
                useReminderRead: false,
                useReminderWrite: false,
                useReminderEdit: false,
                useReminderDelete: false,
                useQuestionPerformance: false,
                useStreakStats: false,
                useJournalSummary: false,
                reason: normalized.reason
            )
        }

        let selectedCount = [
            normalized.useFamilyContext,
            normalized.useReminderRead,
            normalized.useReminderWrite,
            normalized.useReminderEdit,
            normalized.useReminderDelete,
            normalized.useQuestionPerformance,
            normalized.useStreakStats,
            normalized.useJournalSummary,
        ].filter { $0 }.count

        if selectedCount <= 1 {
            return normalized
        }

        // Priority resolution if multiple flags got tripped
        if normalized.useReminderWrite {
            normalized.useFamilyContext = false
            normalized.useReminderRead = false
            normalized.useReminderEdit = false
            normalized.useReminderDelete = false
            normalized.useQuestionPerformance = false
            normalized.useStreakStats = false
            normalized.useJournalSummary = false
            return normalized
        }
        if normalized.useReminderEdit {
            normalized.useFamilyContext = false
            normalized.useReminderRead = false
            normalized.useReminderWrite = false
            normalized.useReminderDelete = false
            normalized.useQuestionPerformance = false
            normalized.useStreakStats = false
            normalized.useJournalSummary = false
            return normalized
        }
        if normalized.useReminderDelete {
            normalized.useFamilyContext = false
            normalized.useReminderRead = false
            normalized.useReminderWrite = false
            normalized.useReminderEdit = false
            normalized.useQuestionPerformance = false
            normalized.useStreakStats = false
            normalized.useJournalSummary = false
            return normalized
        }
        if normalized.useReminderRead {
            normalized.useFamilyContext = false
            normalized.useReminderWrite = false
            normalized.useReminderEdit = false
            normalized.useReminderDelete = false
            normalized.useQuestionPerformance = false
            normalized.useStreakStats = false
            normalized.useJournalSummary = false
            return normalized
        }
        if normalized.useFamilyContext {
            normalized.useQuestionPerformance = false
            normalized.useStreakStats = false
            normalized.useJournalSummary = false
            return normalized
        }
        if normalized.useQuestionPerformance {
            normalized.useStreakStats = false
            normalized.useJournalSummary = false
            return normalized
        }
        if normalized.useStreakStats {
            normalized.useJournalSummary = false
            return normalized
        }

        return normalized
    }
}
#endif
