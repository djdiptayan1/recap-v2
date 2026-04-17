//
//  SmritiFoundationEngine.swift
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
private struct ToolSelectionDecision {
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
#endif

@MainActor
final class SmritiFoundationEngine {
    static let shared = SmritiFoundationEngine()
    private init() {}

    func streamStructuredResponse(
        query: String,
        history: [SmritiHistoryMessage]?,
        context: SmritiPromptContext?,
        fallbackPatientId: String?,
        onPartial: @MainActor @escaping (_ answer: String?, _ followup: String?) -> Void
    ) async -> FoundationStreamOutcome {
#if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        SmritiFoundationPrewarmService.shared.prewarmIfPossible()
        let instructions = selectedInstructions(for: context)
        let prompt = makePrompt(query: query, history: history, context: context)
        let toolPlan = await decideToolPlan(model: model, userQuery: query)
        let tools = buildTools(fallbackPatientId: fallbackPatientId, plan: toolPlan)

        do {
            let session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
            let stream = session.streamResponse(
                to: prompt,
                generating: SmritiGeneratedResponse.self,
                includeSchemaInPrompt: false,
                options: GenerationOptions(sampling: .greedy)
            )

            var latestAnswer = ""
            var latestFollowup: String?

            for try await snapshot in stream {
                let partial = snapshot.content
                if let answer = partial.answer, !answer.isEmpty {
                    latestAnswer = answer
                    await onPartial(answer, nil)
                }
                if let followup = partial.followupPrompt, !followup.isEmpty {
                    latestFollowup = followup
                    await onPartial(nil, followup)
                }
            }

            return .streamed(answer: latestAnswer, followup: latestFollowup)
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            return .guardrail(
                message: "Sorry, this request can’t be handled safely. Please try a different memory-care question."
            )
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = (try? await refusal.explanation)?.content
                ?? "Sorry, I can’t help with that request."
            return .refusal(message: explanation)
        } catch is LanguageModelSession.ToolCallError {
            return await streamStructuredWithoutTools(
                model: model,
                prompt: prompt,
                instructions: instructions,
                onPartial: onPartial
            )
        } catch {
            return .failed
        }
#else
        return .failed
#endif
    }

    func generateStructuredResponse(
        query: String,
        history: [SmritiHistoryMessage]?,
        context: SmritiPromptContext?,
        fallbackPatientId: String?
    ) async -> FoundationStructuredOutcome {
#if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        SmritiFoundationPrewarmService.shared.prewarmIfPossible()
        let instructions = selectedInstructions(for: context)
        let prompt = makePrompt(query: query, history: history, context: context)
        let toolPlan = await decideToolPlan(model: model, userQuery: query)
        let tools = buildTools(fallbackPatientId: fallbackPatientId, plan: toolPlan)

        do {
            let session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
            let generated = try await session.respond(
                to: prompt,
                generating: SmritiGeneratedResponse.self,
                options: GenerationOptions(sampling: .greedy)
            )
            let adapted = SmritiResponse(generated: generated.content)
            return .success(adapted)
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            return .guardrail(
                message: "Sorry, this request can’t be handled safely. Please try a different memory-care question."
            )
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = (try? await refusal.explanation)?.content
                ?? "Sorry, I can’t help with that request."
            return .refusal(message: explanation)
        } catch is LanguageModelSession.ToolCallError {
            return await generateStructuredWithoutTools(
                model: model,
                prompt: prompt,
                instructions: instructions
            )
        } catch {
            return .failed
        }
#else
        return .failed
#endif
    }

#if canImport(FoundationModels)
    private func buildTools(fallbackPatientId: String?, plan: ToolSelectionDecision) -> [any Tool] {
        guard plan.requiresTools else {
            return []
        }

        guard let identity = try? SmritiIdentityResolver.shared.resolve(fallbackPatientId: fallbackPatientId) else {
            return []
        }

        var tools: [any Tool] = []

        if plan.useFamilyContext {
            tools.append(FamilyContextTool(identity: identity))
        }
        if plan.useReminderRead {
            tools.append(ReminderReadTool(identity: identity))
        }
        if plan.useReminderWrite {
            tools.append(ReminderWriteTool(identity: identity))
        }
        if plan.useReminderEdit {
            tools.append(ReminderEditTool(identity: identity))
        }
        if plan.useReminderDelete {
            tools.append(ReminderDeleteTool(identity: identity))
        }
        if plan.useQuestionPerformance {
            tools.append(QuestionPerformanceTool(identity: identity))
        }
        if plan.useStreakStats {
            tools.append(StreakStatsTool(identity: identity))
        }
        if plan.useJournalSummary {
            tools.append(JournalSummaryTool(identity: identity))
        }

        return tools
    }

    private func selectedInstructions(for context: SmritiPromptContext?) -> Instructions {
        if context?.mode == .memoryLane {
            return Instructions {
                """
                You are Smriti in Reminiscence Mode, a warm memory companion for people living with dementia.

                RULES:
                1. Prioritize gentle reminiscence conversation over clinical coaching.
                2. Explore past memories: wedding day, childhood, school days, favorite foods, hobbies, family traditions.
                3. Use family names when available.
                4. Celebrate every memory shared; be patient and encouraging.
                5. Keep language simple, kind, and non-judgmental.
                6. Politely decline unrelated topics.
                7. Never diagnose or prescribe.
                8. Always end with one warm reminiscence follow-up question.
                9. Avoid clinical lists/disclaimers unless explicitly asked for medical-care guidance.
                10. Do not start every response with a greeting or the user's name.
                11. NEVER invent shared memories, events, or places.
                12. If personal memory details are unknown, ask a gentle question instead of guessing.
                13. Use tool outputs as source-of-truth for reminders, family, journal, streak, and daily question data.
                14. If the user explicitly asks to create, edit, or delete a reminder, call the appropriate tool immediately without asking for confirmation.
                15. Call tools only when live app data or an action is required; if not required, answer directly without tools.
                16. For reminder create/edit, set a short, concise title (e.g., "Doctor Appointment", "Take Medicine"). Do NOT stuff all details into the title. Collect required category-specific values first and populate the specific fields (like medicineName, doctorName, etc.). Use the 'notes' field for any extra details (like surgery type, specific instructions). If any required values are missing, ask a focused follow-up question before calling the tool.
                17. For a single user turn, do not call the same read tool repeatedly unless the previous call failed.
                18. Call getFamilyContext ONLY when the user explicitly asks for family member details, relation, or contact info.
                19. For reminder create/edit/delete requests, do not call getFamilyContext unless user explicitly asks for family details.
                """
            }
        }

        return Instructions {
            """
            You are Smriti, a warm Alzheimer's and Dementia Care companion.
            You support patients, caregivers, and families with empathy and evidence-based guidance.

            RULES:
            1. Only discuss Alzheimer's, dementia, memory, elderly care, caregiving, or reminiscence topics.
            2. Politely decline unrelated topics.
            3. Never diagnose or prescribe.
            4. For medical concerns, advise consulting a qualified healthcare professional.
            5. Keep responses concise, calm, and simple.
            6. If user seems confused or frustrated, acknowledge feelings first, then simplify.
            7. Personalize naturally with available patient/family/activity context.
            8. Always include a warm memory-oriented follow-up question.
            9. Include care strategies, sources, and medical disclaimer only when genuinely relevant.
            10. Do not start every response with a greeting or the user's name.
            11. NEVER invent shared memories, events, or places.
            12. If personal memory details are unknown, ask a gentle clarifying question instead of guessing.
            13. Use tool outputs as source-of-truth for reminders, family, journal, streak, and daily question data.
            14. If the user explicitly asks to create, edit, or delete a reminder, call the appropriate tool immediately without asking for confirmation.
            15. Call tools only when live app data or an action is required; if not required, answer directly without tools.
            16. For reminder create/edit, set a short, concise title (e.g., "Doctor Appointment", "Take Medicine"). Do NOT stuff all details into the title. Collect required category-specific values first and populate the specific fields (like medicineName, doctorName, etc.). Use the 'notes' field for any extra details (like surgery type, specific instructions). If any required values are missing, ask a focused follow-up question before calling the tool.
            17. For a single user turn, do not call the same read tool repeatedly unless the previous call failed.
            18. Call getFamilyContext ONLY when the user explicitly asks for family member details, relation, or contact info.
            19. For reminder create/edit/delete requests, do not call getFamilyContext unless user explicitly asks for family details.
            """
        }
    }

    private func decideToolPlan(model: SystemLanguageModel, userQuery: String) async -> ToolSelectionDecision {
        let decisionInstructions = Instructions {
            """
            Decide whether this user message requires app tool calls and select the minimal tool set.

            Output policy:
            - requiresTools = true only when the message needs live in-app data retrieval or an app-side action.
            - For normal advice or conversation, set requiresTools = false and all tool booleans = false.
            - If the request is reminder creation, set useReminderWrite = true only.
            - If the request is reminder update, set useReminderEdit = true only.
            - If the request is reminder deletion, set useReminderDelete = true only.
            - If the request is reminder listing/status, set useReminderRead = true only.
            - Set useFamilyContext = true only when the user explicitly asks about family members, relations, or contacts.
            - Never select family context for reminder create/edit/delete unless family details are explicitly requested.
            - Prefer selecting exactly one tool for a single focused request.
            """
        }

        do {
            let decisionSession = LanguageModelSession(model: model, instructions: decisionInstructions)
            let decision = try await decisionSession.respond(
                to: userQuery,
                generating: ToolSelectionDecision.self,
                options: GenerationOptions(sampling: .greedy)
            )
            return normalizedToolPlan(decision.content, userQuery: userQuery)
        } catch {
            return normalizedToolPlan(fallbackToolPlan(for: userQuery), userQuery: userQuery)
        }
    }

    private func fallbackToolPlan(for userQuery: String) -> ToolSelectionDecision {
        let q = userQuery.lowercased()
        let asksFamily = q.contains("family") || q.contains("relation") || q.contains("contact")
        let asksReminder = q.contains("reminder") || q.contains("medication") || q.contains("medicine")

        let isDeleteReminder = asksReminder && (q.contains("delete") || q.contains("remove") || q.contains("cancel"))
        let isEditReminder = asksReminder && (q.contains("edit") || q.contains("update") || q.contains("change") || q.contains("reschedule"))
        let isReadReminder = asksReminder && (q.contains("list") || q.contains("show") || q.contains("what") || q.contains("upcoming") || q.contains("check"))
        let isWriteReminder = asksReminder && !isDeleteReminder && !isEditReminder && !isReadReminder

        let useJournal = q.contains("journal")
        let useStreak = q.contains("streak")
        let useQuestion = q.contains("question") && (q.contains("daily") || q.contains("performance") || q.contains("score"))

        let requiresTools = asksFamily || asksReminder || useJournal || useStreak || useQuestion

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

    private func normalizedToolPlan(_ plan: ToolSelectionDecision, userQuery: String) -> ToolSelectionDecision {
        var normalized = plan
        let intent = detectPrimaryIntent(in: userQuery)

        switch intent {
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

    private enum PrimaryIntent {
        case reminderCreate
        case reminderEdit
        case reminderDelete
        case reminderRead
        case familyExplicit
        case questionPerformance
        case streakStats
        case journalSummary
        case none
    }

    private func detectPrimaryIntent(in userQuery: String) -> PrimaryIntent {
        let q = userQuery.lowercased()
        let asksReminder = q.contains("remind") || q.contains("medication") || q.contains("medicine")
        let asksFamily = q.contains("family") || q.contains("relation") || q.contains("contact")

        if asksReminder {
            if q.contains("delete") || q.contains("remove") || q.contains("cancel") {
                return .reminderDelete
            }
            if q.contains("edit") || q.contains("update") || q.contains("change") || q.contains("reschedule") {
                return .reminderEdit
            }
            if q.contains("list") || q.contains("show") || q.contains("what") || q.contains("upcoming") || q.contains("check") {
                return .reminderRead
            }
            return .reminderCreate
        }

        if asksFamily {
            return .familyExplicit
        }

        if q.contains("journal") {
            return .journalSummary
        }

        if q.contains("streak") {
            return .streakStats
        }

        if q.contains("question") && (q.contains("daily") || q.contains("performance") || q.contains("score")) {
            return .questionPerformance
        }

        return .none
    }

    private func streamStructuredWithoutTools(
        model: SystemLanguageModel,
        prompt: String,
        instructions: Instructions,
        onPartial: @MainActor @escaping (_ answer: String?, _ followup: String?) -> Void
    ) async -> FoundationStreamOutcome {
        do {
            let session = LanguageModelSession(model: model, instructions: instructions)
            let stream = session.streamResponse(
                to: prompt,
                generating: SmritiGeneratedResponse.self,
                includeSchemaInPrompt: false,
                options: GenerationOptions(sampling: .greedy)
            )

            var latestAnswer = ""
            var latestFollowup: String?

            for try await snapshot in stream {
                let partial = snapshot.content
                if let answer = partial.answer, !answer.isEmpty {
                    latestAnswer = answer
                    await onPartial(answer, nil)
                }
                if let followup = partial.followupPrompt, !followup.isEmpty {
                    latestFollowup = followup
                    await onPartial(nil, followup)
                }
            }

            return .streamed(answer: latestAnswer, followup: latestFollowup)
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            return .guardrail(
                message: "Sorry, this request can’t be handled safely. Please try a different memory-care question."
            )
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = (try? await refusal.explanation)?.content
                ?? "Sorry, I can’t help with that request."
            return .refusal(message: explanation)
        } catch {
            return .failed
        }
    }

    private func generateStructuredWithoutTools(
        model: SystemLanguageModel,
        prompt: String,
        instructions: Instructions
    ) async -> FoundationStructuredOutcome {
        do {
            let session = LanguageModelSession(model: model, instructions: instructions)
            let generated = try await session.respond(
                to: prompt,
                generating: SmritiGeneratedResponse.self,
                options: GenerationOptions(sampling: .greedy)
            )
            let adapted = SmritiResponse(generated: generated.content)
            return .success(adapted)
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            return .guardrail(
                message: "Sorry, this request can’t be handled safely. Please try a different memory-care question."
            )
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            let explanation = (try? await refusal.explanation)?.content
                ?? "Sorry, I can’t help with that request."
            return .refusal(message: explanation)
        } catch {
            return .failed
        }
    }
#endif

    private func makePrompt(
        query: String,
        history: [SmritiHistoryMessage]?,
        context: SmritiPromptContext?
    ) -> String {
        var sections: [String] = []

        if let contextText = context?.asInstructionContextText(), !contextText.isEmpty {
            sections.append("Context:\n\(contextText)")
        }

        if let history, !history.isEmpty {
            let renderedHistory = history.map { "\($0.role): \($0.text)" }.joined(separator: "\n")
            sections.append("Recent chat history (latest 20 turns):\n\(renderedHistory)")
        }

        sections.append("User message:\n\(query)")
        return sections.joined(separator: "\n\n")
    }
}
