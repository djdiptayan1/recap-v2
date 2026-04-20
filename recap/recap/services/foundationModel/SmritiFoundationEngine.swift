//
//  SmritiFoundationEngine.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
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
        let toolPlan = SmritiIntentResolver.resolveToolPlan(for: query, history: history)
        let isReadOnly = toolPlan.requiresTools && !toolPlan.useReminderWrite && !toolPlan.useReminderEdit && !toolPlan.useReminderDelete
        let isHelp = toolPlan.reason == "intent-help"

        // Pre-fetch live data for read operations, AND for edits/deletes so the model knows the exact ID of what to delete/edit
        var liveData: String? = nil
        let needsPrefetch = isReadOnly || toolPlan.useReminderEdit || toolPlan.useReminderDelete
        if needsPrefetch {
            liveData = await prefetchReadData(plan: toolPlan, fallbackPatientId: fallbackPatientId)
        }

        let instructions = SmritiInstructionsProvider.selectedInstructions(for: context, isHelp: isHelp)
        let prompt = SmritiPromptBuilder.makePrompt(query: query, history: history, context: context, liveData: liveData, isHelp: isHelp)

        // Only attach tools for write/action operations — reads are pre-fetched
        let tools: [any Tool]
        if toolPlan.requiresTools && !isReadOnly {
            tools = buildTools(fallbackPatientId: fallbackPatientId, plan: toolPlan)
        } else {
            tools = []
        }
        print("🔧 [Smriti] Tool plan: requiresTools=\(toolPlan.requiresTools) family=\(toolPlan.useFamilyContext) rRead=\(toolPlan.useReminderRead) rWrite=\(toolPlan.useReminderWrite) rEdit=\(toolPlan.useReminderEdit) rDelete=\(toolPlan.useReminderDelete) journal=\(toolPlan.useJournalSummary) streak=\(toolPlan.useStreakStats) questions=\(toolPlan.useQuestionPerformance) reason=\(toolPlan.reason ?? "nil")")
        print("🔧 [Smriti] Tools attached: \(tools.count)")

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
            // Write/action tool failed — fall back to tool-less response
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
        let toolPlan = SmritiIntentResolver.resolveToolPlan(for: query, history: history)
        let isReadOnly = toolPlan.requiresTools && !toolPlan.useReminderWrite && !toolPlan.useReminderEdit && !toolPlan.useReminderDelete
        let isHelp = toolPlan.reason == "intent-help"

        // Pre-fetch live data for read operations, AND for edits/deletes so the model knows the exact ID of what to delete/edit
        var liveData: String? = nil
        let needsPrefetch = isReadOnly || toolPlan.useReminderEdit || toolPlan.useReminderDelete
        if needsPrefetch {
            liveData = await prefetchReadData(plan: toolPlan, fallbackPatientId: fallbackPatientId)
        }

        let instructions = SmritiInstructionsProvider.selectedInstructions(for: context, isHelp: isHelp)
        let prompt = SmritiPromptBuilder.makePrompt(query: query, history: history, context: context, liveData: liveData, isHelp: isHelp)

        // Only attach tools for write/action operations — reads are pre-fetched
        let tools: [any Tool]
        if toolPlan.requiresTools && !isReadOnly {
            tools = buildTools(fallbackPatientId: fallbackPatientId, plan: toolPlan)
        } else {
            tools = []
        }
        print("🔧 [Smriti] Tool plan: requiresTools=\(toolPlan.requiresTools) family=\(toolPlan.useFamilyContext) rRead=\(toolPlan.useReminderRead) rWrite=\(toolPlan.useReminderWrite) rEdit=\(toolPlan.useReminderEdit) rDelete=\(toolPlan.useReminderDelete) journal=\(toolPlan.useJournalSummary) streak=\(toolPlan.useStreakStats) questions=\(toolPlan.useQuestionPerformance) reason=\(toolPlan.reason ?? "nil")")
        print("🔧 [Smriti] Tools attached: \(tools.count)")

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
            // Write/action tool failed — fall back to tool-less response
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


    private func prefetchReadData(plan: ToolSelectionDecision, fallbackPatientId: String?) async -> String? {
        guard let patientId = KeychainManager.shared.getString(key: .patientDocumentID) ??
                              KeychainManager.shared.getString(key: .documentID) ??
                              fallbackPatientId else {
            return nil
        }
        
        var sections: [String] = []
        
        if plan.useReminderRead || plan.useReminderEdit || plan.useReminderDelete {
            sections.append("### Reminders ###")
            do {
                let response: ReminderResponse = try await NetworkManager.shared.request(
                    endpoint: FoundationToolAPI.reminders(patientId: patientId)
                )
                if response.success, !response.data.isEmpty {
                    for reminder in response.data {
                        let timeStr = DateFormatter.localizedString(from: reminder.time, dateStyle: .none, timeStyle: .short)
                        sections.append("- [\(reminder.id)] \(reminder.title) (\(reminder.category.rawValue)) at \(timeStr)")
                    }
                } else {
                    sections.append("No reminders found.")
                }
            } catch {
                sections.append("Failed to load reminders.")
            }
        }
        
        if plan.useFamilyContext {
            sections.append("### Family Context ###")
            do {
                let response: FamilyMemberResponse = try await NetworkManager.shared.request(
                    endpoint: FoundationToolAPI.familyMembers(documentID: patientId)
                )
                if response.success, !response.data.isEmpty {
                    for member in response.data.prefix(6) {
                        sections.append("- \(member.name) (\(member.relation))")
                    }
                } else {
                    sections.append("No family members found.")
                }
            } catch {
                sections.append("Failed to load family members.")
            }
        }
        
        if plan.useJournalSummary {
            sections.append("### Journal Entries ###")
            do {
                let response: JournalResponse = try await NetworkManager.shared.request(
                    endpoint: FoundationToolAPI.journal(patientId: patientId, limit: 5)
                )
                if response.success, !response.data.isEmpty {
                    for entry in response.data {
                        let mood = entry.mood ?? "Neutral"
                        let title = entry.title ?? "Untitled"
                        sections.append("- [\(mood)] \(title)")
                    }
                } else {
                    sections.append("No recent journal entries found.")
                }
            } catch {
                sections.append("Failed to load journal entries.")
            }
        }

        if plan.useStreakStats {
            sections.append("### Streak Stats ###")
            do {
                let response: StreakStatsResponse = try await NetworkManager.shared.request(
                    endpoint: FoundationToolAPI.streakStats(documentID: patientId)
                )
                if response.success {
                    sections.append("Current Streak: \(response.data.currentStreak) days")
                    sections.append("Max Streak: \(response.data.maxStreak) days")
                } else {
                    sections.append("No streak stats found.")
                }
            } catch {
                sections.append("Failed to load streak stats.")
            }
        }

        if plan.useQuestionPerformance {
            sections.append("### Daily Questions ###")
            do {
                let response: QuestionResponse = try await NetworkManager.shared.request(
                    endpoint: FoundationToolAPI.dailyQuestions(patientId: patientId),
                    keyDecodingStrategy: .useDefaultKeys
                )
                if response.success, !response.data.isEmpty {
                    let total = response.data.count
                    let unanswered = response.data.filter { !($0.isAnswered ?? false) }.count
                    sections.append("Questions total: \(total), unanswered: \(unanswered).")
                } else {
                    sections.append("No daily questions found.")
                }
            } catch {
                sections.append("Failed to load daily questions.")
            }
        }
        
        return sections.isEmpty ? nil : sections.joined(separator: "\n")
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
}