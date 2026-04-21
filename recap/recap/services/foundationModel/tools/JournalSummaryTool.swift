//
//  JournalSummaryTool.swift
//  recap
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

struct JournalSummaryTool: Tool {
    let name = "getJournalSummary"
    let description = "Fetches latest journal and memory entries"
    let identity: ResolvedIdentity

    @Generable
    struct Arguments {
        @Guide(description: "Maximum number of recent entries to summarize")
        var limit: Int?
    }

    func call(arguments: Arguments) async throws -> String {
        guard let patientId = identity.patientDocumentId else {
            throw SmritiToolError.missingIdentity
        }

        let limit = max(1, arguments.limit ?? 5)
        let response: JournalResponse = try await NetworkManager.shared.request(
            endpoint: FoundationToolAPI.journal(patientId: patientId, limit: limit),
            keyDecodingStrategy: .useDefaultKeys
        )

        let entries = response.data.prefix(limit).map { entry in
            let title = (entry.title?.isEmpty == false) ? entry.title! : "Untitled"
            let mood = entry.mood ?? "unknown mood"
            return "\(title) [\(mood)]"
        }

        if entries.isEmpty { return "No recent journal entries are available." }
        return "Recent entries: \(entries.joined(separator: "; "))"
    }
}
#endif
