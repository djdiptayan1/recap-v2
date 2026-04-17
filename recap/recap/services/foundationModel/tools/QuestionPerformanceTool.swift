//
//  QuestionPerformanceTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct QuestionPerformanceTool: Tool {
    let name = "getQuestionPerformance"
    let description = "Fetches daily question progress and categories"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Include answered status details")
        var includeAnsweredState: Bool
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        let response: QuestionResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.dailyQuestions(patientId: patientId),
            keyDecodingStrategy: .useDefaultKeys
        )

        let total = response.data.count
        let unanswered = response.data.filter { !($0.isAnswered ?? false) }.count
        let categories = Dictionary(grouping: response.data, by: { $0.category }).mapValues { $0.count }
        let categorySummary = categories.map { "\($0.key): \($0.value)" }.sorted().joined(separator: ", ")

        if arguments.includeAnsweredState {
            return "Questions total: \(total), unanswered: \(unanswered). Category distribution: \(categorySummary)."
        }
        return "Questions total: \(total). Category distribution: \(categorySummary)."
    }
}
#endif
